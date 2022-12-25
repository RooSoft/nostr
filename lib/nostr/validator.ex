defmodule Nostr.Validator do
  alias K256.Schnorr
  alias Nostr.Event

  def validate_event(%Event{} = event) do
    with :ok <- validate_id(event),
         :ok <- validate_signature(event) do
      :ok
    else
      {:error, message} -> {:error, message}
    end
  end

  def validate_id(%Event{id: id} = event) do
    case id == Event.create_id(event) do
      true -> :ok
      false -> {:error, "generated ID and the one in the event don't match"}
    end
  end

  def validate_signature(%Event{id: hex_id, sig: hex_sig, pubkey: hex_pubkey}) do
    id = Binary.from_hex(hex_id)
    sig = Binary.from_hex(hex_sig)
    pubkey = Binary.from_hex(hex_pubkey)

    Schnorr.verify_message_digest(id, sig, pubkey)
  end
end
