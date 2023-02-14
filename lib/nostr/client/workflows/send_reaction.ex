defmodule Nostr.Client.Workflows.SendReaction do
  @moduledoc """
  A process that's responsible to subscribe and listen to relays so
  it can properly enable a user's to send a reaction
  """

  use GenServer

  require Logger

  alias NostrBasics.Keys.PublicKey
  alias NostrBasics.Event
  alias NostrBasics.Event.{Signer, Validator}
  alias NostrBasics.Models.Reaction

  alias Nostr.Client.Relays.RelaySocket

  def start_link(relay_pids, note_id, privkey, content \\ "+") do
    GenServer.start(__MODULE__, %{
      relay_pids: relay_pids,
      note_id: note_id,
      privkey: privkey,
      content: content
    })
  end

  @impl true
  def init(%{relay_pids: relay_pids, note_id: note_id} = state) do
    subscriptions = subscribe_note(relay_pids, note_id)

    {
      :ok,
      state
      |> Map.put(:subscriptions, subscriptions)
      |> Map.put(:got_note, false)
    }
  end

  def handle_info(:unsubscribe, %{subscriptions: subscriptions} = state) do
    unsubscribe(subscriptions)

    {
      :noreply,
      state
      |> Map.put(:subscriptions, [])
    }
  end

  def handle_info(
        {:react, event},
        %{privkey: privkey, content: content, relay_pids: relay_pids} = state
      ) do
    react(event, privkey, content, relay_pids)

    {:noreply, state}
  end

  @impl true
  def handle_info({:end_of_stored_events, _relay, _subscription_id}, state) do
    {:noreply, state}
  end

  @impl true
  # when we first get the note, time to react on it
  def handle_info({_relay, _subscription_id, event}, %{got_note: false} = state) do
    send(self(), {:react, event})
    send(self(), :unsubscribe)

    {
      :noreply,
      state
      |> Map.put(:got_note, true)
    }
  end

  @impl true
  # when the note has already been reacted on
  def handle_info({_relay, _subscription_id, _note}, %{got_note: true} = state) do
    {:noreply, state}
  end

  defp subscribe_note(relay_pids, note_id) do
    relay_pids
    |> Enum.map(fn relay_pid ->
      subscription_id = RelaySocket.subscribe_note(relay_pid, note_id)

      {relay_pid, subscription_id}
    end)
  end

  defp unsubscribe(subscriptions) do
    for {relaysocket_pid, subscription_id} <- subscriptions do
      RelaySocket.unsubscribe(relaysocket_pid, subscription_id)
    end
  end

  defp react(event, privkey, content, relay_pids) do
    pubkey = PublicKey.from_private_key!(privkey)

    {:ok, reaction_event} =
      %Reaction{event_id: event.id, event_pubkey: event.pubkey}
      |> Reaction.to_event(pubkey)

    {:ok, signed_event} =
      %Event{reaction_event | content: content, created_at: DateTime.utc_now()}
      |> Event.add_id()
      |> Signer.sign_event(privkey)

    Validator.validate_event(signed_event)

    for relay_pid <- relay_pids do
      RelaySocket.send_event(relay_pid, signed_event)
    end
  end
end
