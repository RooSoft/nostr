defmodule Nostr.Signer do
  alias Nostr.Event
  alias K256.Schnorr

  def sign_event(%Event{id: id} = event, <<_::256>> = privkey) do
    case Schnorr.create_signature(id, privkey) do
      {:ok, sig} -> {:ok, %{event | sig: sig}}
      {:error, message} -> {:error, message}
    end
  end
end
