defmodule Nostr.Client.Subscriptions.ProfileSubscription do
  @moduledoc """
  A process creating and managing a live subscription to a user's profile
  on a bunch of relays
  """

  use GenServer

  alias Nostr.Client.Relays.RelaySocket

  def start_link([relay_pids, pubkey, subscriber]) do
    GenServer.start_link(__MODULE__, %{
      relay_pids: relay_pids,
      pubkey: pubkey,
      subscriber: subscriber
    })
  end

  @impl true
  def init(%{relay_pids: relay_pids, pubkey: pubkey} = state) do
    Process.flag(:trap_exit, true)

    subscriptions =
      relay_pids
      |> Enum.map(fn relay_pid ->
        RelaySocket.subscribe_profile(relay_pid, pubkey)
      end)

    {
      :ok,
      state
      |> set_profile_subscriptions(subscriptions)
      |> Map.put(:found, false)
    }
  end

  @impl true
  def terminate(_reason, %{relay_pids: relay_pids, subscriptions: subscriptions} = state) do
    unsubscribe_all(relay_pids, subscriptions)

    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:end_of_stored_events, _relay_url, _subscription_id},
        %{found: false} = state
      ) do
    # no profile found

    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:end_of_stored_events, _relay_url, _subscription_id},
        %{found: true} = state
      ) do
    ## nothing to do, we're done here

    {:noreply, state}
  end

  @impl true
  def handle_info(
        {_relay, _subscription_id, event},
        %{subscriber: subscriber} = state
      ) do
    send(subscriber, event)

    {
      :noreply,
      %{state | found: true}
    }
  end

  defp set_profile_subscriptions(state, subscriptions) do
    Map.put(state, :subscriptions, subscriptions)
  end

  defp unsubscribe_all(relay_pids, subscriptions) do
    for relay_pid <- relay_pids, subscription <- subscriptions do
      RelaySocket.unsubscribe(relay_pid, subscription)
    end
  end
end
