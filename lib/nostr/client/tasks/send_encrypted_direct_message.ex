defmodule Nostr.Client.Tasks.SendEncryptedDirectMessage do
  @moduledoc """
  Encrypt and send a direct message
  """

  alias NostrBasics.Keys.{PrivateKey, PublicKey}
  alias NostrBasics.Event
  alias NostrBasics.Event.{Signer, Validator}
  alias NostrBasics.Models.EncryptedDirectMessage

  alias Nostr.Client.Relays.RelaySocket

  @doc """
  Encrypt and send a direct message

  ## Examples
      iex> remote_pubkey = <<0xefc83f01c8fb309df2c8866b8c7924cc8b6f0580afdde1d6e16e2b6107c2862c::256>>
      ...> private_key = <<0x4E22DA43418DD934373CBB38A5AB13059191A2B3A51C5E0B67EB1334656943B8::256>>
      ...> relay_pids = []
      ...> "The Times 03/Jan/2009 Chancellor on brink of second bailout for banks"
      ...> |> Nostr.Client.Tasks.SendEncryptedDirectMessage.execute(remote_pubkey, private_key, relay_pids)
      :ok
  """
  @spec execute(String.t(), PublicKey.id(), PrivateKey.t(), list()) :: :ok | {:error, String.t()}
  def execute(contents, remote_pubkey, private_key, relay_pids) do
    with {:ok, dm_event} <- create_dm_event(contents, remote_pubkey, private_key),
         {:ok, signed_event} <- prepare_and_sign_event(dm_event, private_key) do
      :ok = Validator.validate_event(signed_event)

      send_event(signed_event, relay_pids)

      :ok
    else
      {:error, message} -> {:error, message}
    end
  end

  defp create_dm_event(contents, remote_pubkey, private_key) do
    %EncryptedDirectMessage{content: contents, remote_pubkey: remote_pubkey}
    |> EncryptedDirectMessage.to_event(private_key)
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
