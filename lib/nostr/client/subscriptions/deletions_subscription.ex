defmodule Nostr.Client.Subscriptions.DeletionsSubscription do
  use GenServer

  alias Nostr.RelaySocket
  alias Nostr.Event.Types.EndOfStoredEvents

  def start_link([relay_pids, pubkeys, subscriber]) do
    GenServer.start_link(__MODULE__, %{
      relay_pids: relay_pids,
      pubkeys: pubkeys,
      subscriber: subscriber
    })
  end

  @impl true
  def init(%{relay_pids: relay_pids, pubkeys: pubkeys} = state) do
    relay_pids
    |> Enum.map(fn relay_pid ->
      RelaySocket.subscribe_deletions(relay_pid, pubkeys)
    end)

    {:ok, state}
  end

  @impl true
  def handle_info(profile, %{subscriber: subscriber} = state) do
    send(subscriber, profile)

    {:noreply, state}
  end

  @impl true
  def handle_info(%EndOfStoredEvents{}, state) do
    ## nothing to do

    {:noreply, state}
  end
end
