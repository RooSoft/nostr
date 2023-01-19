defmodule Nostr.RelaySocket.Server do
  @moduledoc """
  The process handling all of the RelaySocket commands
  """

  use GenServer

  require Logger

  alias Mint.{WebSocket}
  alias Nostr.RelaySocket
  alias Nostr.RelaySocket.{Connector, FrameHandler, Publisher, Sender}
  alias Nostr.Client.{SendRequest}

  @impl true
  def init(%{relay_url: relay_url, owner_pid: owner_pid}) do
    case Connector.connect(relay_url) do
      {:ok, conn, ref} ->
        Publisher.successful_connection(owner_pid, relay_url)

        {:ok, %RelaySocket{%RelaySocket{} | url: relay_url, conn: conn, request_ref: ref}}

      {:error, message} ->
        Publisher.unsuccessful_connection(owner_pid, relay_url, message)

        {:stop, message}
    end
  end

  @impl true
  def handle_cast({:unsubscribe, subscription_id}, state) do
    json_request = SendRequest.close(subscription_id)

    state =
      state
      |> remove_subscription(subscription_id)
      |> Sender.send_text(json_request)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:send_event, event}, state) do
    json_request = SendRequest.event(event)

    state =
      state
      |> Sender.send_text(json_request)

    {:noreply, state}
  end

  @impl true
  def handle_call({:subscriptions}, _from, %{subscriptions: subscriptions} = state) do
    {:reply, subscriptions, state}
  end

  @impl true
  def handle_call({:profile, pubkey, subscriber}, _from, state) do
    {atom_subscription_id, json} = Nostr.Client.Request.profile(pubkey)

    state = Sender.send_subscription_request(state, atom_subscription_id, json, subscriber)

    {:reply, atom_subscription_id, state}
  end

  @impl true
  def handle_call({:contacts, pubkey, limit, subscriber}, _from, state) do
    {atom_subscription_id, json} = Nostr.Client.Request.contacts(pubkey, limit)

    state = Sender.send_subscription_request(state, atom_subscription_id, json, subscriber)

    {:reply, atom_subscription_id, state}
  end

  @impl true
  def handle_call({:note, note_id, subscriber}, _from, state) do
    {atom_subscription_id, json} = Nostr.Client.Request.note(note_id)

    state = Sender.send_subscription_request(state, atom_subscription_id, json, subscriber)

    {:reply, atom_subscription_id, state}
  end

  @impl true
  def handle_call({:notes, pubkeys, limit, subscriber}, _from, state) do
    {atom_subscription_id, json} = Nostr.Client.Request.notes(pubkeys, limit)

    state = Sender.send_subscription_request(state, atom_subscription_id, json, subscriber)

    {:reply, atom_subscription_id, state}
  end

  @impl true
  def handle_call({:deletions, pubkeys, limit, subscriber}, _from, state) do
    {atom_subscription_id, json} = Nostr.Client.Request.deletions(pubkeys, limit)

    state = Sender.send_subscription_request(state, atom_subscription_id, json, subscriber)

    {:reply, atom_subscription_id, state}
  end

  @impl true
  def handle_call({:reposts, pubkeys, limit, subscriber}, _from, state) do
    {atom_subscription_id, json} = Nostr.Client.Request.reposts(pubkeys, limit)

    state = Sender.send_subscription_request(state, atom_subscription_id, json, subscriber)

    {:reply, atom_subscription_id, state}
  end

  @impl true
  def handle_call({:reactions, pubkeys, limit, subscriber}, _from, state) do
    {atom_subscription_id, json} = Nostr.Client.Request.reactions(pubkeys, limit)

    state = Sender.send_subscription_request(state, atom_subscription_id, json, subscriber)

    {:reply, atom_subscription_id, state}
  end

  @impl true
  def handle_call({:encrypted_direct_messages, pubkey, limit, subscriber}, _from, state) do
    {atom_subscription_id, json} = Nostr.Client.Request.encrypted_direct_messages(pubkey, limit)

    state = Sender.send_subscription_request(state, atom_subscription_id, json, subscriber)

    {:reply, atom_subscription_id, state}
  end

  @impl true
  def handle_info(message, %{conn: conn, url: url} = state) do
    case WebSocket.stream(conn, message) do
      {:ok, conn, responses} ->
        state = put_in(state.conn, conn) |> handle_responses(responses)
        if state.closing?, do: do_close(state), else: {:noreply, state}

      {:error, _conn, %Mint.TransportError{reason: :closed}, _responses} ->
        {:stop, "#{url} has closed the connection", state}

      {:error, conn, reason, _responses} ->
        Logger.error("in relay_socket some error handle_info happened: #{reason}")
        state = put_in(state.conn, conn) |> reply({:error, reason})
        {:noreply, state}

      :unknown ->
        Logger.error("in relay_socket some :unknown handle_info happened")
        {:noreply, state}
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
    case WebSocket.new(state.conn, ref, state.status, state.resp_headers) do
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

  defp handle_frames(%{conn: conn, subscriptions: subscriptions} = state, frames) do
    Enum.reduce(frames, state, fn
      # reply to pings with pongs
      {:ping, data}, state ->
        Logger.debug("PING #{conn.host}")
        {:ok, state} = Sender.send_pong(state, data)
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
    conn = Sender.close(state)

    {
      :stop,
      :normal,
      put_in(state.conn, conn)
    }
  end

  defp reply(state, response) do
    if state.caller, do: GenServer.reply(state.caller, response)
    put_in(state.caller, nil)
  end

  defp remove_subscription(%{subscriptions: subscriptions} = state, atom_subscription_id) do
    new_subscriptions = subscriptions |> Keyword.delete(atom_subscription_id)

    %{state | subscriptions: new_subscriptions}
  end
end
