defmodule Nostr.Client.Subscriptions.KindsSubscription do
  @moduledoc """
  A process creating and managing a live subscription to some kinds of events
  on a bunch of relays
  """

  use GenServer

  require Logger

  alias Nostr.Client.Relays.RelaySocket

  def start_link([relay_pids, kinds, subscriber]) do
    GenServer.start_link(__MODULE__, %{
      relay_pids: relay_pids,
      kinds: kinds,
      subscriber: subscriber
    })
  end

  @impl true
  def init(%{relay_pids: relay_pids, kinds: kinds} = state) do
    Process.flag(:trap_exit, true)

    send(self(), {:connect, relay_pids, kinds})

    {:ok, state}
  end

  @impl true
  def terminate(_reason, %{relay_pids: relay_pids, subscriptions: subscriptions} = state) do
    unsubscribe_all(relay_pids, subscriptions)

    {:noreply, state}
  end

  @impl true
  def handle_info({:connect, relay_pids, kinds}, state) do
    subscriptions =
      relay_pids
      |> Enum.map(fn relay_pid ->
        RelaySocket.subscribe_kinds(relay_pid, kinds)
      end)

    {
      :noreply,
      state
      |> set_kinds_subscriptions(subscriptions)
    }
  end

  @impl true
  def handle_info({:end_of_stored_events, relay_url, subscription_id}, state) do
    ## nothing to do
    Logger.debug("got an EOSE from #{relay_url} for #{subscription_id}")

    {:noreply, state}
  end

  @impl true
  def handle_info(note, %{subscriber: subscriber} = state) do
    send(subscriber, note)

    {:noreply, state}
  end

  defp set_kinds_subscriptions(state, subscriptions) do
    Map.put(state, :subscriptions, subscriptions)
  end

  defp unsubscribe_all(relay_pids, subscriptions) do
    for relay_pid <- relay_pids, subscription <- subscriptions do
      RelaySocket.unsubscribe(relay_pid, subscription)
    end
  end
end
