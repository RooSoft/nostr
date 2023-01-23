defmodule Nostr.Crypto.AES256CBC do
  @moduledoc """
  Algorithm that encrypts and decrypts direct messages
  """

  @spec encrypt(String.t(), <<_::256>>, <<_::256>>) :: String.t()
  def encrypt(message, seckey, pubkey) do
    iv = :crypto.strong_rand_bytes(16)

    shared_secret = get_shared_secret(seckey, pubkey)

    cipher_text =
      :crypto.crypto_one_time(:aes_256_cbc, shared_secret, iv, message,
        encrypt: true,
        padding: :pkcs_padding
      )

    b64_cypher_text = Base.encode64(cipher_text)
    b64_iv = Base.encode64(iv)

    "#{b64_cypher_text}?iv=#{b64_iv}"
  end

  @spec decrypt(String.t(), <<_::256>>, <<_::256>>) ::
          {:ok, String.t()} | {:error, atom() | String.t()}
  def decrypt(message, seckey, pubkey) do
    [message, iv] = String.split(message, "?iv=")

    with {:ok, message} <- Base.decode64(message),
         {:ok, iv} <- Base.decode64(iv) do
      shared_secret = get_shared_secret(seckey, pubkey)

      decrypted =
        :crypto.crypto_one_time(:aes_256_cbc, shared_secret, iv, message,
          encrypt: false,
          padding: :pkcs_padding
        )

      {:ok, decrypted}
    else
      {:error, message} -> {:error, message}
      :error -> {:error, "cannot decode iv, which should be in base64"}
    end
  end

  defp get_shared_secret(<<_::256>> = seckey, <<_::256>> = pubkey) do
    :crypto.compute_key(
      :ecdh,
      <<0x02::8, pubkey::bitstring-256>>,
      seckey,
      :secp256k1
    )
  end
end
