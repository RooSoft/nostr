defmodule Nostr.Client.Relays.RelaySocket.MessageDispatcher do
  @moduledoc """
  Sends websocket messages to the right destination
  """

  require Logger

  alias Mint.{WebSocket}
  alias Nostr.Client.Relays.RelaySocket.{FrameHandler, Publisher, Sender}

  def dispatch(message, %{conn: conn, url: url, owner_pid: owner_pid} = state) do
    case WebSocket.stream(conn, message) do
      {:ok, conn, responses} ->
        state = put_in(state.conn, conn) |> handle_responses(responses)
        if state.closing?, do: do_close(state), else: {:noreply, state}

      {:error, _conn, %Mint.TransportError{} = error, _responses} ->
        Publisher.transport_error(owner_pid, url, error.reason)
        {:stop, {:shutdown, "#{url} has closed the connection"}, state}

      {:error, conn, reason, _responses} ->
        Publisher.transport_error(owner_pid, url, "#{inspect(reason)}")
        state = put_in(state.conn, conn) |> reply({:error, reason})
        {:noreply, state}

      :unknown ->
        Publisher.transport_error(owner_pid, url, "an unknown error happened in Mint.WebSockets")
        {:noreply, state}
    end
  end

  defp reply(state, response) do
    if state.caller, do: GenServer.reply(state.caller, response)
    put_in(state.caller, nil)
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

  defp handle_responses(%{request_ref: ref, owner_pid: owner_pid, url: url} = state, [
         {:done, ref} | rest
       ]) do
    case WebSocket.new(state.conn, ref, state.status, state.resp_headers) do
      {:ok, conn, websocket} ->
        Publisher.websockets_ready(owner_pid, url)

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
    case WebSocket.decode(websocket, data) do
      {:ok, websocket, frames} ->
        put_in(state.websocket, websocket)
        |> handle_frames(frames)
        |> handle_responses(rest)

      {:error, websocket, reason} ->
        Logger.error("error parsing websocket data: #{reason}")

        put_in(state.websocket, websocket)
        |> reply({:error, reason})
    end
  end

  defp handle_responses(state, [_response | rest]) do
    handle_responses(state, rest)
  end

  defp handle_responses(state, []), do: state

  defp handle_frames(
         %{subscriptions: subscriptions, url: url, owner_pid: owner_pid} = state,
         frames
       ) do
    Enum.reduce(frames, state, fn
      # reply to pings with pongs
      {:ping, data}, state ->
        Publisher.ping(owner_pid, url)
        ### TODO: seen this call return a {:error, _}, please manage this
        {:ok, state} = Sender.send_pong(state, data)
        state

      {:close, code, reason}, state ->
        Publisher.close(owner_pid, url, code, reason)
        %{state | closing?: true}

      {:text, text}, state ->
        FrameHandler.handle_text_frame(text, subscriptions, url, owner_pid)
        state

      frame, state ->
        Publisher.unexpected_frame(owner_pid, url, frame)
        state
    end)
  end

  defp do_close(state) do
    # Streaming a close frame may fail if the server has already closed
    # for writing.
    conn = Sender.close(state)

    {
      :stop,
      :normal,
      put_in(state.conn, conn)
    }
  end
end
