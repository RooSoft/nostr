defmodule Nostr.Client.Workflows.DeleteEvents do
  @moduledoc """
  A process that's responsible to subscribe and listen to relays so
  it can properly delete a bunch of events
  """

  use GenServer

  require Logger

  alias NostrBasics.Event
  alias NostrBasics.Event.{Signer, Validator}
  alias NostrBasics.Keys.PublicKey

  alias Nostr.Models.Delete
  alias Nostr.Client.Relays.RelaySocket

  def start_link(relay_pids, event_ids, note, privkey) do
    GenServer.start(__MODULE__, %{
      relay_pids: relay_pids,
      privkey: privkey,
      event_ids: event_ids,
      note: note
    })
  end

  @impl true
  def init(%{event_ids: event_ids, note: note} = state) do
    send(self(), {:delete, event_ids, note})

    {
      :ok,
      state
      |> Map.put(:treated, false)
    }
  end

  @impl true
  def handle_info(
        {:delete, event_ids, note},
        %{treated: false, privkey: privkey, relay_pids: relay_pids} = state
      ) do
    delete_event(event_ids, note, privkey, relay_pids)

    {
      :noreply,
      state
      |> Map.put(:treated, true)
    }
  end

  defp delete_event(event_ids, note, privkey, relay_pids) do
    pubkey = PublicKey.from_private_key!(privkey)

    {:ok, delete_event} =
      %Delete{event_ids: event_ids, note: note}
      |> Delete.to_event(pubkey)

    {:ok, signed_event} =
      %Event{delete_event | created_at: DateTime.utc_now()}
      |> Event.add_id()
      |> Signer.sign_event(privkey)

    :ok = Validator.validate_event(signed_event)

    send_event(signed_event, relay_pids)
  end

  defp send_event(validated_event, relay_pids) do
    for relay_pid <- relay_pids do
      RelaySocket.send_event(relay_pid, validated_event)
    end
  end
end
