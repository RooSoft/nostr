defmodule Nostr.Client.Subscriptions.RecommendedServersSubscription do
  @moduledoc """
  A process creating and managing a live subscription to a user's recommended
  servers on a bunch of relays
  """

  use GenServer

  alias Nostr.Client.Relays.RelaySocket
  alias Nostr.Event.Types.{RecommendedServerEvent, EndOfStoredEvents}

  def start_link([relay_pids, subscriber]) do
    GenServer.start_link(__MODULE__, %{
      relay_pids: relay_pids,
      subscriber: subscriber
    })
  end

  @impl true
  def init(%{relay_pids: relay_pids} = state) do
    subscriptions =
      relay_pids
      |> Enum.map(fn relay_pid ->
        RelaySocket.subscribe_recommended_servers(relay_pid)
      end)

    {
      :ok,
      state
      |> set_recommended_servers_subscriptions(subscriptions)
      |> Map.put(:found, false)
    }
  end

  @impl true
  def handle_info({:end_of_stored_events, relay_url, subscription_id}, state) do
    IO.inspect("EOSE in note subscription #{relay_url} #{subscription_id}")
    ## nothing to do

    {:noreply, state}
  end

  @impl true
  def handle_info({_relay_url, %EndOfStoredEvents{}}, %{found: true} = state) do
    ## nothing to do, we're done here

    {:noreply, state}
  end

  @impl true
  def handle_info(
        {_relay_url, %RecommendedServerEvent{} = event},
        %{subscriber: subscriber} = state
      ) do
    send(subscriber, event)

    {
      :noreply,
      %{state | found: true}
    }
  end

  defp set_recommended_servers_subscriptions(state, subscriptions) do
    Map.put(state, :subscriptions, subscriptions)
  end
end
