defmodule Nostr.Client.Subscriptions.AllSubscription do
  @moduledoc """
  A process creating and managing a live subscription to all that's going through
  a bunch of relays
  """

  use GenServer

  require Logger

  alias Nostr.Client.Relays.RelaySocket

  def start_link([relay_pids, subscriber]) do
    GenServer.start_link(__MODULE__, %{
      relay_pids: relay_pids,
      subscriber: subscriber
    })
  end

  @impl true
  def init(%{relay_pids: relay_pids} = state) do
    Process.flag(:trap_exit, true)

    send(self(), {:connect, relay_pids})

    {:ok, state}
  end

  @impl true
  def terminate(_reason, %{relay_pids: relay_pids, subscriptions: subscriptions} = state) do
    unsubscribe_all(relay_pids, subscriptions)

    {:noreply, state}
  end

  @impl true
  def handle_info({:connect, relay_pids}, state) do
    subscriptions =
      relay_pids
      |> Enum.map(fn relay_pid ->
        RelaySocket.subscribe_all(relay_pid)
      end)

    {
      :noreply,
      state
      |> set_subscriptions(subscriptions)
    }
  end

  @impl true
  def handle_info({:end_of_stored_events, relay_url, subscription_id}, state) do
    ## nothing to do
    Logger.debug("got an EOSE from #{relay_url} for #{subscription_id}")

    {:noreply, state}
  end

  @impl true
  def handle_info(event, %{subscriber: subscriber} = state) do
    IO.inspect(event, label: "in all_subscription")

    send(subscriber, event)

    {:noreply, state}
  end

  defp set_subscriptions(state, subscriptions) do
    Map.put(state, :subscriptions, subscriptions)
  end

  defp unsubscribe_all(relay_pids, subscriptions) do
    for relay_pid <- relay_pids, subscription <- subscriptions do
      RelaySocket.unsubscribe(relay_pid, subscription)
    end
  end
end
