defmodule Nostr.Client.Workflows.SendReaction do
  @moduledoc """
  A process that's responsible to subscribe and listen to relays so
  it can properly enable a user's to send a reaction
  """

  use GenServer

  require Logger

  alias Nostr.RelaySocket
  alias Nostr.Event.{Signer, Validator}
  alias Nostr.Event.Types.{ReactionEvent, EndOfStoredEvents}

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
      |> Map.put(:treated, false)
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
        {:react, note},
        %{privkey: privkey, content: content, relay_pids: relay_pids} = state
      ) do
    react(note, privkey, content, relay_pids)

    {:noreply, state}
  end

  @impl true
  def handle_info({_relay, %EndOfStoredEvents{}}, state) do
    ## nothing to do

    {:noreply, state}
  end

  @impl true
  # when we first get the note, time to react on it
  def handle_info({_relay, note}, %{treated: false} = state) do
    send(self(), {:react, note})
    send(self(), :unsubscribe)

    {
      :noreply,
      state
      |> Map.put(:treated, true)
    }
  end

  @impl true
  # when the note has already been reacted on
  def handle_info({_relay, _note}, %{treated: true} = state) do
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

  defp react(note, privkey, content, relay_pids) do
    pubkey = Nostr.Keys.PublicKey.from_private_key!(privkey)

    {:ok, signed_event} =
      note
      |> ReactionEvent.create_event(content, pubkey)
      |> Signer.sign_event(privkey)

    Validator.validate_event(signed_event)

    for relay_pid <- relay_pids do
      RelaySocket.send_event(relay_pid, signed_event)
    end
  end
end
