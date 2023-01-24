defmodule Nostr.RelaySocket.Server do
  @moduledoc """
  The process handling all of the RelaySocket commands
  """

  use GenServer

  require Logger

  alias Nostr.RelaySocket
  alias Nostr.RelaySocket.{Connector, MessageDispatcher, Publisher, Sender}
  alias Nostr.Client.{SendRequest}

  @impl true
  def init(%{relay_url: relay_url, owner_pid: owner_pid}) do
    case Connector.connect(relay_url) do
      {:ok, conn, ref} ->
        Publisher.successful_connection(owner_pid, relay_url)

        {:ok,
         %RelaySocket{
           %RelaySocket{}
           | url: relay_url,
             conn: conn,
             request_ref: ref,
             owner_pid: owner_pid
         }}

      {:error, message} ->
        Publisher.unsuccessful_connection(owner_pid, relay_url, message)

        {:stop, "error in RelaySocket init: #{message}"}
    end
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
  def handle_info(message, state) do
    MessageDispatcher.dispatch(message, state)
  end
end
