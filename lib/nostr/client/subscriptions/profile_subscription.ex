defmodule Nostr.Client.Subscriptions.ProfileSubscription do
  @moduledoc """
  A process creating and managing a live subscription to a user's profile
  on a bunch of relays
  """

  use GenServer

  alias Nostr.Client.Relays.RelaySocket
  alias Nostr.Event.Types.{MetadataEvent, EndOfStoredEvents}

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
        {_relay_url, %Nostr.Event.Types.EndOfStoredEvents{}},
        %{found: false, pubkey: pubkey, subscriber: subscriber} = state
      ) do
    empty_event = MetadataEvent.create_empty_event(pubkey)

    send(subscriber, empty_event)

    {:noreply, state}
  end

  @impl true
  def handle_info({_relay_url, %EndOfStoredEvents{}}, %{found: true} = state) do
    ## nothing to do, we're done here

    {:noreply, state}
  end

  @impl true
  def handle_info(
        {_relay_url, %MetadataEvent{} = event},
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
