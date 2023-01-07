defmodule Nostr.Client.Subscriptions.TimelineSubscription do
  use GenServer

  alias Nostr.RelaySocket
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
    relay_pids
    |> Enum.map(fn relay_pid ->
      RelaySocket.subscribe_contacts(relay_pid, pubkey)
    end)

    {:ok, state}
  end

  @impl true
  def handle_info(
        {_relay_url, %ContactList{contacts: contacts}},
        %{relay_pids: relay_pids, pubkey: _pubkey, subscriber: _subscriber} = state
      ) do
    pubkeys =
      contacts
      |> Enum.map(& &1.pubkey)

    relay_pids
    |> Enum.map(fn relay_pid ->
      RelaySocket.subscribe_notes(relay_pid, pubkeys)
    end)

    {:noreply, state}
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
end
