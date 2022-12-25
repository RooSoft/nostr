defmodule Nostr.Validator do
  alias K256.Schnorr
  alias Nostr.Crypto

  @text_event_kind 1

  def validate_note(%Nostr.Event.TextEvent{} = event) do
    with :ok <- validate_id(event),
         :ok <- validate_signature(event) do
      :ok
    else
      {:error, message} -> {:error, message}
    end
  end

  def validate_id(%Nostr.Event.TextEvent{id: id} = event) do
    case id == create_id(event) do
      true -> :ok
      false -> {:error, "generated ID and the one in the event don't match"}
    end
  end

  def validate_signature(%Nostr.Event.TextEvent{id: hex_id, sig: hex_sig, pubkey: hex_pubkey}) do
    id = Binary.from_hex(hex_id)
    sig = Binary.from_hex(hex_sig)
    pubkey = Binary.from_hex(hex_pubkey)

    Schnorr.verify_message_digest(id, sig, pubkey)
  end

  defp create_id(%Nostr.Event.TextEvent{
         pubkey: pubkey,
         created_at: created_at,
         tags: tags,
         content: content
       }) do
    [
      0,
      pubkey,
      created_at |> DateTime.to_unix(),
      @text_event_kind,
      tags,
      content
    ]
    |> Jason.encode!()
    |> Crypto.sha256()
    |> Binary.to_hex()
  end
end
