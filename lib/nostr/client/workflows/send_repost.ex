defmodule Nostr.Client.Workflows.SendRepost do
  @moduledoc """
  A process that's responsible to subscribe and listen to relays so
  it can properly enable a user's to send a repost
  """

  use GenServer

  require Logger

  alias NostrBasics.Event.{Signer, Validator}
  alias NostrBasics.Keys.PublicKey

  alias Nostr.Client.Relays.RelaySocket
  alias Nostr.Event.Types.{RepostEvent}

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
        {:repost, note, found_on_relay},
        %{privkey: privkey, relay_pids: relay_pids} = state
      ) do
    repost(note, found_on_relay, privkey, relay_pids)

    {:noreply, state}
  end

  ## TODO figure out what to do with this case once NostrBasics refactoring is done
  #
  # @impl true
  # def handle_info({_relay, %EndOfStoredEvents{}}, state) do
  #   ## nothing to do

  #   {:noreply, state}
  # end

  @impl true
  # when we first get the note, time to repost it
  def handle_info({relay, note}, %{treated: false} = state) do
    send(self(), {:repost, note, relay})
    send(self(), :unsubscribe)

    {
      :noreply,
      state
      |> Map.put(:treated, true)
    }
  end

  @impl true
  # when the note has already been reposted
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

  defp repost(note, found_on_relay, privkey, relay_pids) do
    pubkey = PublicKey.from_private_key!(privkey)

    {:ok, signed_event} =
      note
      |> RepostEvent.create_event(pubkey, [found_on_relay])
      |> Signer.sign_event(privkey)

    Validator.validate_event(signed_event)

    for relay_pid <- relay_pids do
      RelaySocket.send_event(relay_pid, signed_event)
    end
  end
end
