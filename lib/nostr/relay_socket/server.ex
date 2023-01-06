defmodule Nostr.RelaySocket.Server do
  use GenServer

  require Logger
  require Mint.HTTP

  alias Nostr.RelaySocket
  alias Nostr.RelaySocket.FrameHandler
  alias Nostr.Client.{SendRequest}

  @impl true
  def init(%{relay_url: relay_url}) do
    {:ok, %{conn: conn, request_ref: ref}} = connect(relay_url)

    {:ok, %{%RelaySocket{} | conn: conn, request_ref: ref}}
  end

  @impl true
  def handle_cast({:send_event, event}, state) do
    json_request = SendRequest.event(event)

    {:ok, state} = send_frame(state, {:text, json_request})

    {:noreply, state}
  end

  @impl true
  def handle_cast({:profile, pubkey, subscriber}, state) do
    {id, json} = Nostr.Client.Request.profile(pubkey)

    {:ok, state} = send_frame(state, {:text, json})

    atom_id = id |> String.to_atom()

    {
      :noreply,
      %{state | subscriptions: [{atom_id, subscriber} | state.subscriptions]}
    }
  end

  @impl true
  def handle_cast({:contacts, pubkey, subscriber}, state) do
    {id, json} = Nostr.Client.Request.contacts(pubkey)

    {:ok, state} = send_frame(state, {:text, json})

    atom_id = id |> String.to_atom()

    {
      :noreply,
      %{state | subscriptions: [{atom_id, subscriber} | state.subscriptions]}
    }
  end

  @impl true
  def handle_cast({:notes, pubkeys, subscriber}, state) do
    {id, json} = Nostr.Client.Request.notes(pubkeys)

    {:ok, state} = send_frame(state, {:text, json})

    atom_id = id |> String.to_atom()

    {
      :noreply,
      %{state | subscriptions: [{atom_id, subscriber} | state.subscriptions]}
    }
  end

  @impl true
  def handle_info(message, %{conn: conn} = state) do
    case Mint.WebSocket.stream(conn, message) do
      {:ok, conn, responses} ->
        state = put_in(state.conn, conn) |> handle_responses(responses)
        if state.closing?, do: do_close(state), else: {:noreply, state}

      {:error, conn, reason, _responses} ->
        state = put_in(state.conn, conn) |> reply({:error, reason})
        {:noreply, state}

      :unknown ->
        {:noreply, state}
    end
  end

  defp connect(relay_url) do
    uri = URI.parse(relay_url)

    http_scheme =
      case uri.scheme do
        "ws" -> :http
        "wss" -> :https
      end

    ws_scheme =
      case uri.scheme do
        "ws" -> :ws
        "wss" -> :wss
      end

    path = "/"

    with {:ok, conn} <- Mint.HTTP.connect(http_scheme, uri.host, uri.port),
         {:ok, conn, ref} <- Mint.WebSocket.upgrade(ws_scheme, conn, path, []) do
      {:ok, %{conn: conn, request_ref: ref}}
    else
      {:error, reason} ->
        {:error, reason}

      {:error, _conn, reason} ->
        {:error, reason}
    end
  end

  defp handle_responses(state, responses)

  defp handle_responses(%{request_ref: ref} = state, [{:status, ref, status} | rest]) do
    put_in(state.status, status)
    |> handle_responses(rest)
  end

  defp handle_responses(%{request_ref: ref} = state, [{:headers, ref, resp_headers} | rest]) do
    put_in(state.resp_headers, resp_headers)
    |> handle_responses(rest)
  end

  defp handle_responses(%{request_ref: ref} = state, [{:done, ref} | rest]) do
    case Mint.WebSocket.new(state.conn, ref, state.status, state.resp_headers) do
      {:ok, conn, websocket} ->
        %{state | conn: conn, websocket: websocket, status: nil, resp_headers: nil}
        |> reply({:ok, :connected})
        |> handle_responses(rest)

      {:error, conn, reason} ->
        put_in(state.conn, conn)
        |> reply({:error, reason})
    end
  end

  defp handle_responses(%{request_ref: ref, websocket: websocket} = state, [
         {:data, ref, data} | rest
       ])
       when websocket != nil do
    case Mint.WebSocket.decode(websocket, data) do
      {:ok, websocket, frames} ->
        put_in(state.websocket, websocket)
        |> handle_frames(frames)
        |> handle_responses(rest)

      {:error, websocket, reason} ->
        put_in(state.websocket, websocket)
        |> reply({:error, reason})
    end
  end

  defp handle_responses(state, [_response | rest]) do
    handle_responses(state, rest)
  end

  defp handle_responses(state, []), do: state

  defp send_frame(state, frame) do
    with {:ok, websocket, data} <- Mint.WebSocket.encode(state.websocket, frame),
         state = put_in(state.websocket, websocket),
         {:ok, conn} <- Mint.WebSocket.stream_request_body(state.conn, state.request_ref, data) do
      {:ok, put_in(state.conn, conn)}
    else
      {:error, %Mint.WebSocket{} = websocket, reason} ->
        {:error, put_in(state.websocket, websocket), reason}

      {:error, conn, reason} ->
        {:error, put_in(state.conn, conn), reason}
    end
  end

  defp handle_frames(%{subscriptions: subscriptions} = state, frames) do
    Enum.reduce(frames, state, fn
      # reply to pings with pongs
      {:ping, data}, state ->
        {:ok, state} = send_frame(state, {:pong, data})
        state

      {:close, _code, reason}, state ->
        Logger.debug("Closing connection: #{inspect(reason)}")
        %{state | closing?: true}

      {:text, text}, state ->
        FrameHandler.handle_text_frame(text, subscriptions)
        state

      frame, state ->
        Logger.debug("Unexpected frame received: #{inspect(frame)}")
        state
    end)
  end

  defp do_close(state) do
    # Streaming a close frame may fail if the server has already closed
    # for writing.
    _ = send_frame(state, :close)
    Mint.HTTP.close(state.conn)
    {:stop, :normal, state}
  end

  defp reply(state, response) do
    if state.caller, do: GenServer.reply(state.caller, response)
    put_in(state.caller, nil)
  end
end
