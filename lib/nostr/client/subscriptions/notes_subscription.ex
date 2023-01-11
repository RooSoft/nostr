defmodule Nostr.Client.Subscriptions.NotesSubscription do
  use GenServer

  alias Nostr.RelaySocket
  alias Nostr.Event.Types.EndOfStoredEvents

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
      RelaySocket.subscribe_notes(relay_pid, [pubkey])
    end)

    {:ok, state}
  end

  @impl true
  def handle_info(note, %{subscriber: subscriber} = state) do
    send(subscriber, note)

    {:noreply, state}
  end

  @impl true
  def handle_info(%EndOfStoredEvents{}, state) do
    ## nothing to do

    {:noreply, state}
  end
end
