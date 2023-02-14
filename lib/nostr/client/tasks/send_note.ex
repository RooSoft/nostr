defmodule Nostr.Client.Tasks.SendNote do
  @moduledoc """
  Sends a note
  """

  alias NostrBasics.Keys.{PrivateKey, PublicKey}
  alias NostrBasics.Event
  alias NostrBasics.Event.{Signer, Validator}
  alias NostrBasics.Models.Note

  alias Nostr.Client.Relays.RelaySocket

  @doc """
  Sends a note

  ## Examples
      iex> private_key = <<0x4E22DA43418DD934373CBB38A5AB13059191A2B3A51C5E0B67EB1334656943B8::256>>
      ...> relay_pids = []
      ...> "The Times 03/Jan/2009 Chancellor on brink of second bailout for banks"
      ...> |> Nostr.Client.Tasks.SendNote.execute(private_key, relay_pids)
      :ok
  """
  @spec execute(String.t(), PrivateKey.t(), list()) :: :ok | {:error, String.t()}
  def execute(contents, private_key, relay_pids) do
    with {:ok, pubkey} <- PublicKey.from_private_key(private_key),
         {:ok, dm_event} <- create_note_event(contents, pubkey),
         {:ok, signed_event} <- prepare_and_sign_event(dm_event, private_key) do
      :ok = Validator.validate_event(signed_event)

      send_event(signed_event, relay_pids)

      :ok
    else
      {:error, message} -> {:error, message}
    end
  end

  defp create_note_event(contents, private_key) do
    %Note{content: contents}
    |> Note.to_event(private_key)
  end

  defp prepare_and_sign_event(event, private_key) do
    %Event{event | created_at: DateTime.utc_now()}
    |> Event.add_id()
    |> Signer.sign_event(private_key)
  end

  defp send_event(validated_event, relay_pids) do
    for relay_pid <- relay_pids do
      RelaySocket.send_event(relay_pid, validated_event)
    end
  end
end
