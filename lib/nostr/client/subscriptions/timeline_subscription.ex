defmodule Nostr.Client.Subscriptions.TimelineSubscription do
  @moduledoc """
  A process creating and managing a live timeline subscription on a bunch of relays
  """

  use GenServer

  alias Nostr.Client.RelaySocket
  alias Nostr.Event.Types.EndOfStoredEvents

  alias Nostr.Models.{ContactList}

  def start_link([relay_pids, pubkey, subscriber]) do
    GenServer.start_link(__MODULE__, %{
      relay_pids: relay_pids,
      pubkey: pubkey,
      subscriber: subscriber
    })
  end

  @impl true
  def init(%{relay_pids: relay_pids, pubkey: pubkey} = state) do
    subscriptions =
      relay_pids
      |> Enum.map(fn relay_pid ->
        RelaySocket.subscribe_contacts(relay_pid, pubkey)
      end)

    {
      :ok,
      state
      |> set_note_subscriptions(subscriptions)
    }
  end

  @impl true
  def handle_info(
        {_relay_url, %ContactList{contacts: contacts}},
        %{relay_pids: relay_pids, pubkey: _pubkey, subscriber: _subscriber} = state
      ) do
    pubkeys =
      contacts
      |> Enum.map(& &1.pubkey)

    unsubscribe_all_notes(state)

    new_subscriptions =
      relay_pids
      |> Enum.map(fn relay_pid ->
        subscription_id = RelaySocket.subscribe_notes(relay_pid, pubkeys, 1)
        {relay_pid, subscription_id}
      end)

    {:noreply, state |> set_note_subscriptions(new_subscriptions)}
  end

  @impl true
  def handle_info({relay_url, event}, %{subscriber: subscriber} = state) do
    send(subscriber, {relay_url, event})

    {:noreply, state}
  end

  @impl true
  def handle_info(%EndOfStoredEvents{}, state) do
    ## nothing to do

    {:noreply, state}
  end

  defp unsubscribe_all_notes(%{subscriptions: subscriptions}) do
    for {relay_pid, subscription_id} <- subscriptions do
      RelaySocket.unsubscribe(relay_pid, subscription_id)
    end
  end

  defp set_note_subscriptions(state, subscriptions) do
    Map.put(state, :subscriptions, subscriptions)
  end
end
