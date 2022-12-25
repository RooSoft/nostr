defmodule Nostr.Validator do
  alias K256.Schnorr

  def validate_note(%Nostr.Event.TextEvent{} = event) do
    id = Binary.from_hex(event.id)
    sig = Binary.from_hex(event.sig)
    pubkey = Binary.from_hex(event.pubkey)

    validate_signature(id, sig, pubkey)
  end

  defp validate_signature(id, sig, pubkey) do
    Schnorr.verify_message_digest(id, sig, pubkey)
  end
end
