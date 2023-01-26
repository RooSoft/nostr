defmodule Nostr.Client.Subscriptions.NoteSubscription do
  @moduledoc """
  A process creating and managing a live subscription to a user's note
  on a bunch of relays
  """

  use GenServer

  alias Nostr.Client.RelaySocket
  alias Nostr.Event.Types.EndOfStoredEvents

  def start_link([relay_pids, note_id, subscriber]) do
    GenServer.start_link(__MODULE__, %{
      relay_pids: relay_pids,
      note_id: note_id,
      subscriber: subscriber
    })
  end

  @impl true
  def init(%{relay_pids: relay_pids, note_id: note_id} = state) do
    subscriptions =
      relay_pids
      |> Enum.map(fn relay_pid ->
        RelaySocket.subscribe_note(relay_pid, note_id)
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
