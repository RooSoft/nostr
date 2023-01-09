defmodule Nostr.RelaySocket.Server do
  use GenServer

  require Logger
  require Mint.HTTP

  alias Nostr.RelaySocket
  alias Nostr.RelaySocket.FrameHandler
  alias Nostr.Client.{SendRequest}

  @impl true
  def init(%{relay_url: relay_url, owner_pid: owner_pid}) do
    case connect(relay_url) do
      {:ok, %{conn: conn, request_ref: ref}} ->
        send(owner_pid, {:connection, relay_url, :ok})
        {:ok, %{%RelaySocket{} | conn: conn, request_ref: ref}}

      {:error, message} ->
        send(owner_pid, {:connection, relay_url, :error, message})
        {:stop, message}
    end
  end

  @impl true
  def handle_cast({:unsubscribe, subscription_id}, state) do
    json_request = SendRequest.close(subscription_id)

    {:ok, state} =
      state
      |> remove_subscription(subscription_id)
      |> send_frame({:text, json_request})

    {:noreply, state}
  end

  @impl true
  def handle_cast({:send_event, event}, state) do
    json_request = SendRequest.event(event)

    {:ok, state} = send_frame(state, {:text, json_request})

    {:noreply, state}
  end

  @impl true
  def handle_call({:subscriptions}, _from, %{subscriptions: subscriptions} = state) do
    {:reply, subscriptions, state}
  end

  @impl true
  def handle_call({:profile, pubkey, subscriber}, _from, state) do
    {id, json} = Nostr.Client.Request.profile(pubkey)
    atom_subscription_id = id |> String.to_atom()

    {:ok, state} = send_frame(state, {:text, json})

    {
      :reply,
      atom_subscription_id,
      state |> add_subscription(atom_subscription_id, subscriber)
    }
  end

  @impl true
  def handle_call({:contacts, pubkey, limit, subscriber}, _from, state) do
    {id, json} = Nostr.Client.Request.contacts(pubkey, limit)
    atom_subscription_id = id |> String.to_atom()

    state =
      case send_frame(state, {:text, json}) do
        {:ok, state} ->
          state |> add_subscription(atom_subscription_id, subscriber)

        {:error, _socket, error} ->
          Logger.error("#{inspect(error)}")
          state
      end

    {:reply, atom_subscription_id, state}
  end

  @impl true
  def handle_call({:notes, pubkeys, limit, subscriber}, _from, state) do
    {request_id, json} = Nostr.Client.Request.notes(pubkeys, limit)

    {:ok, state} = send_frame(state, {:text, json})

    atom_subscription_id = request_id |> String.to_atom()

    {
      :reply,
      atom_subscription_id,
      state |> add_subscription(atom_subscription_id, subscriber)
    }
  end

  @impl true
  def handle_call({:reactions, pubkeys, limit, subscriber}, _from, state) do
    {request_id, json} = Nostr.Client.Request.reactions(pubkeys, limit)

    {:ok, state} = send_frame(state, {:text, json})

    atom_subscription_id = request_id |> String.to_atom()

    {
      :reply,
      atom_subscription_id,
      state |> add_subscription(atom_subscription_id, subscriber)
    }
  end

  @impl true
  def handle_call({:reposts, pubkeys, limit, subscriber}, _from, state) do
    {request_id, json} = Nostr.Client.Request.reposts(pubkeys, limit)

    {:ok, state} = send_frame(state, {:text, json})

    atom_subscription_id = request_id |> String.to_atom()

    {
      :reply,
      atom_subscription_id,
      state |> add_subscription(atom_subscription_id, subscriber)
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

    with {:ok, conn} <- Mint.HTTP.connect(http_scheme, uri.host, uri.port, protocols: [:http1]),
         {:ok, conn, ref} <- Mint.WebSocket.upgrade(ws_scheme, conn, path, []) do
      {:ok, %{conn: conn, request_ref: ref}}
    else
      {:error, reason} ->
        Logger.error(reason)
        {:error, reason}

      {:error, _conn, reason} ->
        Logger.error(reason)
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

  defp handle_frames(%{conn: conn, subscriptions: subscriptions} = state, frames) do
    Enum.reduce(frames, state, fn
      # reply to pings with pongs
      {:ping, data}, state ->
        IO.puts("PING #{conn.host}")
        {:ok, state} = send_frame(state, {:pong, data})
        state

      {:close, _code, reason}, state ->
        Logger.debug("Closing connection: #{inspect(reason)}")
        %{state | closing?: true}

      {:text, text}, state ->
        FrameHandler.handle_text_frame(text, subscriptions, conn)
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

  defp add_subscription(state, atom_subscription_id, subscriber) do
    %{state | subscriptions: [{atom_subscription_id, subscriber}] ++ state.subscriptions}
  end

  defp remove_subscription(%{subscriptions: subscriptions} = state, atom_subscription_id) do
    new_subscriptions = subscriptions |> Keyword.delete(atom_subscription_id)

    %{state | subscriptions: new_subscriptions}
  end
end