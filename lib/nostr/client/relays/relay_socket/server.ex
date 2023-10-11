defmodule Nostr.Client.Relays.RelaySocket.Server do
  @moduledoc """
  The process handling all of the RelaySocket commands
  """

  use GenServer

  require Logger

  alias Nostr.Client.Relays.RelaySocket
  alias Nostr.Client.Relays.RelaySocket.{Connector, MessageDispatcher, Publisher, Sender}
  alias Nostr.Client.{SendRequest}

  @impl true
  def init(%{relay_url: relay_url, owner_pid: owner_pid}) do
    Logger.info("Starting a relay socket for #{relay_url}, #{inspect self()}")

    send(self(), {:connect_to_relay, relay_url, owner_pid})

    {:ok, %RelaySocket{}}
  end

  @impl true
  def terminate(reason, state) do
    Logger.warning("A relay socket is terminating: #{inspect reason}")

    {:ok, state}
  end

  @impl true
  def handle_cast({:unsubscribe, subscription_id}, state) do
    state =
      state
      |> Sender.send_close_message(subscription_id)

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
  def handle_call({:all, limit, subscriber}, _from, state) do
    {subscription_id, json} = Nostr.Client.Request.all(limit)

    send(self(), {:subscription_request, state, subscription_id, json, subscriber})

    {:reply, subscription_id, state}
  end

  @impl true
  def handle_call(:ready?, _from, %RelaySocket{websocket: nil} = state) do
    {:reply, false, state}
  end

  @impl true
  def handle_call(:ready?, _from, %RelaySocket{websocket: _} = state) do
    {:reply, true, state}
  end

  @impl true
  def handle_call(:url, _from, %RelaySocket{conn: conn} = state) do
    url = ~s(#{conn.private.scheme}://#{conn.host}:#{conn.port})

    IO.inspect("URL: #{url}")
    IO.inspect state

    {:reply, url, state}
  end

  @impl true
  def handle_call(
        command,
        _from,
        %RelaySocket{url: url, owner_pid: owner_pid, websocket: nil} = state
      ) do
    command_name = elem(command, 0)
    reason = "Can't execute #{command_name} on #{url}, as websockets aren't enabled yet"

    Publisher.not_ready(owner_pid, url, reason)

    {:noreply, state}
  end

  @impl true
  def handle_call({:subscriptions}, _from, %{subscriptions: subscriptions} = state) do
    {:reply, subscriptions, state}
  end

  @impl true
  def handle_call({:profile, public_key, subscriber}, _from, state) do
    {subscription_id, json} = Nostr.Client.Request.profile(public_key)

    send(self(), {:subscription_request, state, subscription_id, json, subscriber})

    {:reply, subscription_id, state}
  end

  @impl true
  def handle_call({:recommended_servers, subscriber}, _from, state) do
    {subscription_id, json} = Nostr.Client.Request.recommended_servers()

    send(self(), {:subscription_request, state, subscription_id, json, subscriber})

    {:reply, subscription_id, state}
  end

  @impl true
  def handle_call({:contacts, pubkey, limit, subscriber}, _from, state) do
    {subscription_id, json} = Nostr.Client.Request.contacts(pubkey, limit)

    send(self(), {:subscription_request, state, subscription_id, json, subscriber})

    {:reply, subscription_id, state}
  end

  @impl true
  def handle_call({:note, note_id, subscriber}, _from, state) do
    {subscription_id, json} = Nostr.Client.Request.note(note_id)

    send(self(), {:subscription_request, state, subscription_id, json, subscriber})

    {:reply, subscription_id, state}
  end

  @impl true
  def handle_call({:kinds, kinds, limit, subscriber}, _from, state) do
    {subscription_id, json} = Nostr.Client.Request.kinds(kinds, limit)

    send(self(), {:subscription_request, state, subscription_id, json, subscriber})

    {:reply, subscription_id, state}
  end

  @impl true
  def handle_call({:notes, pubkeys, limit, subscriber}, _from, state) do
    {subscription_id, json} = Nostr.Client.Request.notes(pubkeys, limit)

    IO.puts json

    send(self(), {:subscription_request, state, subscription_id, json, subscriber})

    {:reply, subscription_id, state}
  end

  @impl true
  def handle_call({:deletions, pubkeys, limit, subscriber}, _from, state) do
    {subscription_id, json} = Nostr.Client.Request.deletions(pubkeys, limit)

    send(self(), {:subscription_request, state, subscription_id, json, subscriber})

    {:reply, subscription_id, state}
  end

  @impl true
  def handle_call({:reposts, pubkeys, limit, subscriber}, _from, state) do
    {subscription_id, json} = Nostr.Client.Request.reposts(pubkeys, limit)

    send(self(), {:subscription_request, state, subscription_id, json, subscriber})

    {:reply, subscription_id, state}
  end

  @impl true
  def handle_call({:reactions, pubkeys, limit, subscriber}, _from, state) do
    {subscription_id, json} = Nostr.Client.Request.reactions(pubkeys, limit)

    send(self(), {:subscription_request, state, subscription_id, json, subscriber})

    {:reply, subscription_id, state}
  end

  @impl true
  def handle_call({:encrypted_direct_messages, pubkey, limit, subscriber}, _from, state) do
    {subscription_id, json} = Nostr.Client.Request.encrypted_direct_messages(pubkey, limit)

    send(self(), {:subscription_request, state, subscription_id, json, subscriber})

    {:reply, subscription_id, state}
  end

  @impl true
  def handle_info({:connect_to_relay, relay_url, owner_pid}, relaysocket) do
    case Connector.connect(relay_url) do
      {:ok, conn, ref} ->
        Publisher.successful_connection(owner_pid, relay_url)

        {
          :noreply,
          %RelaySocket{
            relaysocket
            | url: relay_url,
              conn: conn,
              request_ref: ref,
              owner_pid: owner_pid
          }
        }

      {:error, e} ->
        message = Exception.message(e)

        Publisher.unsuccessful_connection(owner_pid, relay_url, message)

        {:stop, {:shutdown, "error in RelaySocket init: #{message}"}}
    end
  end

  @impl true
  def handle_info({:subscription_request, state, subscription_id, json, subscriber}, state) do
    state = Sender.send_subscription_request(state, subscription_id, json, subscriber)

    {:noreply, state}
  end

  @impl true
  def handle_info(message, state) do
    MessageDispatcher.dispatch(message, state)
  end
end
