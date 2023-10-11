defmodule Nostr.Client.Subscriptions.ContactsSubscription do
  @moduledoc """
  A process creating and managing a live subscription to a user's contact list
  on a bunch of relays
  """

  use GenServer

  require Logger

  alias Nostr.Client.Relays.RelaySocket

  def start([relay_pid, pubkey, subscriber]), do: start(relay_pid, pubkey, subscriber)

  def start(relay_pid, pubkey, subscriber \\ self()) when is_pid(relay_pid) do
    Logger.info("#{inspect(relay_pid)} contacts subscription: #{inspect(pubkey)}")

    GenServer.start(__MODULE__, %{
      relay_pid: relay_pid,
      pubkey: pubkey,
      subscriber: subscriber
    })
  end

  @impl true
  def init(state) do
    Process.flag(:trap_exit, true)

    send(self(), :connect)

    {:ok, state}
  end

  @impl true
  def terminate(_reason, %{relay_pid: relay_pid} = state) do
    if(Map.has_key?(state, :relay_subscription)) do
      subscription = Map.get(state, :relay_subscription)
      unsubscribe(relay_pid, subscription)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:connect, %{relay_pid: relay_pid, pubkey: pubkey} = state) do
    case Process.alive?(relay_pid) do
      true ->
        subscription = RelaySocket.subscribe_contacts(relay_pid, pubkey)

        {
          :noreply,
          state
          |> set_contract_subscription(subscription)
        }

      false ->
        Process.flag(:trap_exit, false)
        Process.exit(self(), "disconnected relay, can't subscribe to contacts")

        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:end_of_stored_events, _relay_url, _subscription_id}, state) do
    ## nothing to do

    {:noreply, state}
  end

  @impl true
  def handle_info(profile, %{subscriber: subscriber} = state) do
    send(subscriber, profile)

    {:noreply, state}
  end

  defp set_contract_subscription(state, subscription) do
    Map.put(state, :relay_subscription, subscription)
  end

  defp unsubscribe(relay_pid, subscription) do
    RelaySocket.unsubscribe(relay_pid, subscription)
  end
end
