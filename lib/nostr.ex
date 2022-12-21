defmodule Nostr do
  alias K256.Schnorr

  def sign_message(message, secret_key) do
    secret_key_as_list = Binary.to_list(secret_key)

    with {:ok, signature} = Schnorr.create_signature(secret_key_as_list, message),
         {:ok, verifying_key} = Schnorr.create_verifying_key(secret_key_as_list),
         :ok = Schnorr.validate_signature(message, signature, verifying_key) do
      Binary.from_list(signature)
    end
  end
end
