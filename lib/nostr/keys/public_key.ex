defmodule Nostr.Keys.PublicKey do
  @doc """
  Issues the public key corresponding to a given private key

  ## Examples
      iex> private_key = <<0xb6907368a945db7769b5eaecd73c3c175b77c64e1df3e9900acd66aeea7b53ab::256>>
      ...> Nostr.Keys.PublicKey.from_private_key(private_key)
      {:ok, <<0x6d72da1aa56f82aa9a7a8a7f2a94f46e2a80a6686dd60c182bbbc8ebef5811b1::256>>}
  """
  @spec from_private_key(<<_::256>>) :: {:ok, <<_::256>>} | {:error, binary()}
  def from_private_key(private_key) do
    K256.Schnorr.verifying_key_from_signing_key(private_key)
  end

  @doc """
  Converts a bech32 string into a binary public key that can be used with this lib

  ## Examples
      iex> npub = "npub1d4ed5x49d7p24xn63flj4985dc4gpfngdhtqcxpth0ywhm6czxcscfpcq8"
      ...> Nostr.Keys.PublicKey.from_npub(npub)
      {:ok, <<0x6d72da1aa56f82aa9a7a8a7f2a94f46e2a80a6686dd60c182bbbc8ebef5811b1::256>>}
  """
  @spec from_npub(binary()) :: {:ok, binary()} | {:error, binary()}
  def from_npub("npub" <> _ = bech32_pubkey) do
    case Bech32.decode(bech32_pubkey) do
      {:ok, "npub", pubkey} -> {:ok, pubkey}
      {:ok, _, _} -> {:error, "malformed bech32 public key"}
      {:error, message} -> {:error, message}
    end
  end
end
