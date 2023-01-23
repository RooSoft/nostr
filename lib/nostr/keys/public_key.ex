defmodule Nostr.Keys.PublicKey do
  @moduledoc """
  Public keys management functions
  """

  alias Nostr.Keys.PrivateKey
  alias K256.Schnorr

  @doc """
  Issues the public key corresponding to a given private key

  ## Examples
      iex> private_key = <<0xb6907368a945db7769b5eaecd73c3c175b77c64e1df3e9900acd66aeea7b53ab::256>>
      ...> Nostr.Keys.PublicKey.from_private_key(private_key)
      {:ok, <<0x6d72da1aa56f82aa9a7a8a7f2a94f46e2a80a6686dd60c182bbbc8ebef5811b1::256>>}
  """
  @spec from_private_key(<<_::256>>) ::
          {:ok, <<_::256>>} | {:error, String.t() | :signing_key_decoding_failed}
  def from_private_key(private_key) do
    case PrivateKey.to_binary(private_key) do
      {:ok, binary_private_key} ->
        Schnorr.verifying_key_from_signing_key(binary_private_key)

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Issues the public key corresponding to a given private key

  ## Examples
      iex> private_key = <<0xb6907368a945db7769b5eaecd73c3c175b77c64e1df3e9900acd66aeea7b53ab::256>>
      ...> Nostr.Keys.PublicKey.from_private_key!(private_key)
      <<0x6d72da1aa56f82aa9a7a8a7f2a94f46e2a80a6686dd60c182bbbc8ebef5811b1::256>>
  """
  @spec from_private_key!(<<_::256>>) :: <<_::256>>
  def from_private_key!(private_key) do
    case from_private_key(private_key) do
      {:ok, public_key} -> public_key
      {:error, :signing_key_decoding_failed} -> raise "signing key decoding failed"
      {:error, message} -> raise message
    end
  end

  @doc """
  Converts a public key in the npub format into a binary public key that can be used with this lib

  ## Examples
      iex> npub = "npub1d4ed5x49d7p24xn63flj4985dc4gpfngdhtqcxpth0ywhm6czxcscfpcq8"
      ...> Nostr.Keys.PublicKey.from_npub(npub)
      {:ok, <<0x6d72da1aa56f82aa9a7a8a7f2a94f46e2a80a6686dd60c182bbbc8ebef5811b1::256>>}
  """
  @spec from_npub(binary()) :: {:ok, binary()} | {:error, String.t()}
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
  @spec to_hex(<<_::256>>) :: String.t()
  def to_hex(pubkey) do
    Binary.to_hex(pubkey)
  end

  @doc """
  Does its best to convert any public key format to binary, issues an error if it can't

  ## Examples
      iex> "npub1mxrssnzg8y9zjr6a9g6xqwhxfa23xlvmftluakxqatsrp6ez9gjssu0htc"
      ...> |> Nostr.Keys.PublicKey.to_binary()
      { :ok, <<0xd987084c48390a290f5d2a34603ae64f55137d9b4affced8c0eae030eb222a25::256>> }
  """
  @spec to_binary(<<_::256>> | String.t() | list(<<_::256>>)) ::
          {:ok, <<_::256>>} | {:error, String.t()}
  def to_binary(<<_::256>> = public_key), do: {:ok, public_key}
  def to_binary("npub" <> _ = public_key), do: from_npub(public_key)

  def to_binary(public_keys) when is_list(public_keys) do
    public_keys
    |> Enum.reverse()
    |> Enum.reduce({:ok, []}, &reduce_to_binaries/2)
  end

  def to_binary(not_lowercase_npub) do
    case String.downcase(not_lowercase_npub) do
      "npub" <> _ = npub -> from_npub(npub)
      _ -> {:error, "#{not_lowercase_npub} is not a valid public key"}
    end
  end

  defp reduce_to_binaries(public_key, acc) do
    case acc do
      {:ok, binary_public_keys} ->
        case to_binary(public_key) do
          {:ok, binary_public_key} ->
            {:ok, [binary_public_key | binary_public_keys]}

          {:error, message} ->
            {:error, message}
        end

      {:error, message} ->
        {:error, message}
    end
  end
end
