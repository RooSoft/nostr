defmodule Nostr.Client.Workflows.DeleteEvents do
  @moduledoc """
  A process that's responsible to subscribe and listen to relays so
  it can properly delete a bunch of events
  """

  use GenServer

  require Logger

  alias Nostr.Client.Relays.RelaySocket
  alias Nostr.Event.{Signer, Validator}
  alias Nostr.Event.Types.{DeleteEvent}

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
    pubkey = Nostr.Keys.PublicKey.from_private_key!(privkey)

    with event <- DeleteEvent.create_event(event_ids, note, pubkey),
         {:ok, signed_event} <- Signer.sign_event(event, privkey) do
      Validator.validate_event(signed_event)
      send_event(signed_event, relay_pids)
    else
      {:error, message} ->
        Logger.warning(message)
    end
  end

  defp send_event(validated_event, relay_pids) do
    for relay_pid <- relay_pids do
      RelaySocket.send_event(relay_pid, validated_event)
    end
  end
end
