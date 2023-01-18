defmodule Nostr.Client.Subscriptions.ReactionsSubscription do
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
        RelaySocket.subscribe_reactions(relay_pid, pubkeys)
      end)

    {
      :ok,
      state
      |> set_reactions_subscriptions(subscriptions)
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

  defp set_reactions_subscriptions(state, subscriptions) do
    Map.put(state, :subscriptions, subscriptions)
  end
end
