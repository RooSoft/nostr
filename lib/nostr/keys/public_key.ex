defmodule Nostr.Keys.PublicKey do
  @moduledoc """
  Public keys management functions
  """

  @doc """
  Issues the public key corresponding to a given private key

  ## Examples
      iex> private_key = <<0xb6907368a945db7769b5eaecd73c3c175b77c64e1df3e9900acd66aeea7b53ab::256>>
      ...> Nostr.Keys.PublicKey.from_private_key(private_key)
      {:ok, <<0x6d72da1aa56f82aa9a7a8a7f2a94f46e2a80a6686dd60c182bbbc8ebef5811b1::256>>}
  """
  @spec from_private_key(K256.Schnorr.signing_key()) ::
          {:ok, K256.Schnorr.verifying_key()} | {:error, :signing_key_decoding_failed}
  def from_private_key(private_key) do
    K256.Schnorr.verifying_key_from_signing_key(private_key)
  end

  @doc """
  Issues the public key corresponding to a given private key

  ## Examples
      iex> private_key = <<0xb6907368a945db7769b5eaecd73c3c175b77c64e1df3e9900acd66aeea7b53ab::256>>
      ...> Nostr.Keys.PublicKey.from_private_key!(private_key)
      <<0x6d72da1aa56f82aa9a7a8a7f2a94f46e2a80a6686dd60c182bbbc8ebef5811b1::256>>
  """
  @spec from_private_key!(K256.Schnorr.signing_key()) :: K256.Schnorr.verifying_key()
  def from_private_key!(private_key) do
    case from_private_key(private_key) do
      {:ok, public_key} -> public_key
      {:error, :signing_key_decoding_failed} -> raise "signing key decoding failed"
    end
  end

  @doc """
  Converts a public key in the npub format into a binary public key that can be used with this lib

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

  @doc """
  Converts a public key in the npub format into a binary public key that can be used with this lib

  ## Examples
      iex> npub = "npub1d4ed5x49d7p24xn63flj4985dc4gpfngdhtqcxpth0ywhm6czxcscfpcq8"
      ...> Nostr.Keys.PublicKey.from_npub!(npub)
      <<0x6d72da1aa56f82aa9a7a8a7f2a94f46e2a80a6686dd60c182bbbc8ebef5811b1::256>>
  """
  @spec from_npub!(binary()) :: <<_::256>>
  def from_npub!("npub" <> _ = bech32_pubkey) do
    case from_npub(bech32_pubkey) do
      {:ok, pubkey} -> pubkey
      {:error, message} -> raise message
    end
  end

  @doc """
  Encodes a public key into the npub format

  ## Examples
      iex> public_key = <<0x6d72da1aa56f82aa9a7a8a7f2a94f46e2a80a6686dd60c182bbbc8ebef5811b1::256>>
      ...> Nostr.Keys.PublicKey.to_npub(public_key)
      "npub1d4ed5x49d7p24xn63flj4985dc4gpfngdhtqcxpth0ywhm6czxcscfpcq8"
  """
  @spec to_npub(<<_::256>>) :: binary()
  def to_npub(<<_::256>> = public_key) do
    Bech32.encode("npub", public_key)
  end

  @doc """
  Converts a public key into a string containing hex characters

  ## Examples
      iex> public_key = <<0x6d72da1aa56f82aa9a7a8a7f2a94f46e2a80a6686dd60c182bbbc8ebef5811b1::256>>
      ...> Nostr.Keys.PublicKey.to_hex(public_key)
      "6d72da1aa56f82aa9a7a8a7f2a94f46e2a80a6686dd60c182bbbc8ebef5811b1"
  """
  @spec to_hex(K256.Schnorr.verifying_key()) :: String.t()
  def to_hex(pubkey) do
    Binary.to_hex(pubkey)
  end
end
