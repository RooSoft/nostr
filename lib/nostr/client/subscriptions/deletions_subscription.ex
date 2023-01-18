defmodule Nostr.Client.Subscriptions.DeletionsSubscription do
  @moduledoc """
  A process creating and managing a live subscription to a user's deletion events
  on a bunch of relays
  """

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
    subscriptions =
      relay_pids
      |> Enum.map(fn relay_pid ->
        RelaySocket.subscribe_deletions(relay_pid, pubkeys)
      end)

    {
      :ok,
      state
      |> set_deletion_subscriptions(subscriptions)
    }
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

  defp set_deletion_subscriptions(state, subscriptions) do
    Map.put(state, :subscriptions, subscriptions)
  end
end
