defmodule Nostr.Client.Subscriptions.EncryptedDirectMessagesSubscription do
  @moduledoc """
  A process creating and managing a live subscription to a user's encrypted
  direct messages on a bunch of relays
  """

  use GenServer

  alias NostrBasics.Event
  alias NostrBasics.Keys.PublicKey

  alias Nostr.Client.Relays.RelaySocket

  def start_link([relay_pids, private_key, subscriber]) do
    GenServer.start_link(__MODULE__, %{
      relay_pids: relay_pids,
      private_key: private_key,
      subscriber: subscriber
    })
  end

  @impl true
  def init(%{relay_pids: relay_pids, private_key: private_key} = state) do
    case PublicKey.from_private_key(private_key) do
      {:ok, public_key} ->
        subscriptions =
          relay_pids
          |> Enum.map(fn relay_pid ->
            RelaySocket.subscribe_encrypted_direct_messages(relay_pid, public_key)
          end)

        {
          :ok,
          state
          |> Map.put(:public_key, public_key)
          |> set_encrypted_direct_messages_subscriptions(subscriptions)
        }

      {:error, message} ->
        {:stop, {:shutdown, message}}
    end
  end

  @impl true
  def handle_info({:end_of_stored_events, _relay_url, _subscription_id}, state) do
    ## nothing to do

    {:noreply, state}
  end

  @impl true
  def handle_info(
        {_relay_url, _subscription_id, %Event{} = event},
        %{subscriber: subscriber} = state
      ) do
    send(subscriber, event)

    {:noreply, state}
  end

  defp set_encrypted_direct_messages_subscriptions(state, subscriptions) do
    Map.put(state, :subscriptions, subscriptions)
  end
end
