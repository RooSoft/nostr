defmodule Nostr.Client.Workflows.SendRepost do
  @moduledoc """
  A process that's responsible to subscribe and listen to relays so
  it can properly enable a user's to send a repost
  """

  use GenServer

  require Logger

  alias NostrBasics.Event
  alias NostrBasics.Event.{Signer, Validator}
  alias NostrBasics.Keys.PublicKey

  alias Nostr.Client.Relays.RelaySocket
  alias Nostr.Models.Repost

  def start_link(relay_pids, note_id, privkey) do
    GenServer.start(__MODULE__, %{
      relay_pids: relay_pids,
      note_id: note_id,
      privkey: privkey
    })
  end

  @impl true
  def init(%{relay_pids: relay_pids, note_id: note_id} = state) do
    subscriptions = subscribe_note(relay_pids, note_id)

    {
      :ok,
      state
      |> Map.put(:subscriptions, subscriptions)
      |> Map.put(:note_received?, false)
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
        {:repost, note, found_on_relay},
        %{privkey: privkey, relay_pids: relay_pids} = state
      ) do
    repost(note, found_on_relay, privkey, relay_pids)

    {:noreply, state}
  end

  @impl true
  def handle_info({:end_of_stored_events, _relay, _subscription_id}, state) do
    {:noreply, state}
  end

  @impl true
  # when we first get the note, time to repost it
  def handle_info({relay, _subscription_id, note}, %{note_received?: false} = state) do
    send(self(), {:repost, note, relay})
    send(self(), :unsubscribe)

    {
      :noreply,
      state
      |> Map.put(:note_received?, true)
    }
  end

  @impl true
  # when the note has already been reposted
  def handle_info({_relay, _subscription_id, _note}, %{note_received?: true} = state) do
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

  defp repost(event, found_on_relay, privkey, relay_pids) do
    pubkey = PublicKey.from_private_key!(privkey)

    {:ok, repost} =
      %Repost{event: event, relays: [found_on_relay]}
      |> Repost.to_event(pubkey)

    {:ok, signed_event} =
      %Event{repost | created_at: DateTime.utc_now()}
      |> Event.add_id()
      |> Signer.sign_event(privkey)

    Validator.validate_event(signed_event)

    for relay_pid <- relay_pids do
      RelaySocket.send_event(relay_pid, signed_event)
    end
  end
end
