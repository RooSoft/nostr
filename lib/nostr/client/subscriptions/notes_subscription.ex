defmodule Nostr.Client.Subscriptions.NotesSubscription do
  @moduledoc """
  A process creating and managing a live subscription to a user's notes
  on a bunch of relays
  """

  use GenServer

  require Logger

  alias Nostr.Client.Relays.RelaySocket

  def start([relay_pid, pubkeys, subscriber]), do: start(relay_pid, pubkeys, subscriber)

  def start(relay_pid, pubkeys, subscriber \\ self()) when is_pid(relay_pid) do
    Logger.info("#{inspect(relay_pid)} notes subscription: #{inspect(pubkeys)}")

    GenServer.start(__MODULE__, %{
      relay_pid: relay_pid,
      pubkeys: pubkeys,
      subscriber: subscriber,
      relay_subscriptions: []
    })
  end

  @impl true
  def init(%{relay_pid: relay_pid, pubkeys: pubkeys} = state) do
    Process.flag(:trap_exit, true)

    Logger.warning("NEW SUBSCRIPTION- ---------------- #{inspect(self())}")

    send(self(), {:connect, relay_pid, pubkeys})

    {:ok, state}
  end

  @impl true
  def terminate(
        _reason,
        %{relay_pid: relay_pid, relay_subscriptions: relay_subscriptions} = state
      ) do
    Logger.warning("the #{inspect(self())} note subscription is terminating")

    unsubscribe(relay_pid, relay_subscriptions)

    {:noreply, state}
  end

  @impl true
  def terminate(reason, %{relay_pid: relay_pid, subscriber: subscriber} = state) do
    Logger.warning(
      "TERMINATE EVENT: #{inspect(relay_pid)} #{inspect(subscriber)}, #{inspect(reason)}"
    )

    {:noreply, state}
  end

  @impl true
  def handle_info({:connect, relay_pid, pubkeys}, state) do
    case Process.alive?(relay_pid) do
      true ->
        subscription = RelaySocket.subscribe_notes(relay_pid, pubkeys)

        {
          :noreply,
          state
          |> add_notes_subscription(subscription)
        }

      false ->
        Process.flag(:trap_exit, false)
        Process.exit(self(), "disconnected relay, can't subscribe to notes")

        {:noreply, state}
    end
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

  defp add_notes_subscription(%{relay_subscriptions: relay_subscriptions} = state, subscription) do
    %{state | relay_subscriptions: [subscription | relay_subscriptions]}
  end

  defp unsubscribe(relay_pid, subscriptions) do
    for subscription <- subscriptions do
      RelaySocket.unsubscribe(relay_pid, subscription)
    end
  end
end
