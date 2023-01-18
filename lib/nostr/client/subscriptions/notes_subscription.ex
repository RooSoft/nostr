defmodule Nostr.Client.Subscriptions.NotesSubscription do
  @moduledoc """
  A process creating and managing a live subscription to a user's notes
  on a bunch of relays
  """

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
    subscriptions =
      relay_pids
      |> Enum.map(fn relay_pid ->
        RelaySocket.subscribe_notes(relay_pid, [pubkey])
      end)

    {
      :ok,
      state
      |> set_note_subscriptions(subscriptions)
    }
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

  defp set_note_subscriptions(state, subscriptions) do
    Map.put(state, :subscriptions, subscriptions)
  end
end
