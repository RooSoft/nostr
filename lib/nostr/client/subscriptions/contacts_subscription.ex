defmodule Nostr.Client.Subscriptions.ContactsSubscription do
  @moduledoc """
  A process creating and managing a live subscription to a user's contact list
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
        RelaySocket.subscribe_contacts(relay_pid, pubkey)
      end)

    {
      :ok,
      state
      |> set_contract_subscriptions(subscriptions)
    }
  end

  @impl true
  def terminate(_reason, %{relay_pids: relay_pids, subscriptions: subscriptions} = state) do
    unsubscribe_all(relay_pids, subscriptions)

    {:noreply, state}
  end

  @impl true
  def handle_info({:end_of_stored_events, relay_url, subscription_id}, state) do
    ## nothing to do

    {:noreply, state}
  end

  @impl true
  def handle_info(profile, %{subscriber: subscriber} = state) do
    IO.puts("CONTACTS FROM HERE")

    send(subscriber, profile)

    {:noreply, state}
  end

  defp set_contract_subscriptions(state, subscriptions) do
    Map.put(state, :subscriptions, subscriptions)
  end

  defp unsubscribe_all(relay_pids, subscriptions) do
    for relay_pid <- relay_pids, subscription <- subscriptions do
      RelaySocket.unsubscribe(relay_pid, subscription)
    end
  end
end
