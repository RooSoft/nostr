defmodule Nostr.Crypto do
  @doc """
  Computes [SHA256](https://en.wikipedia.org/wiki/SHA-2) on a binary and returns it as a binary
  ## Examples
      iex> "6c7ab2f961a1bc3f13cdc08dc41c3f439adebd549a8ef1c089e81a5907376107"
      ...> |> Nostr.Crypto.sha256()
      <<171, 106, 143, 29, 158, 43, 3, 51, 223, 248, 227, 112, 237, 111, 223, 226, 11, 46, 128, 8, 224, 69, 239, 179, 251, 50, 152, 194, 47, 117, 105, 218>>
  """
  @spec sha256(String.t()) :: <<_::256>>
  def sha256(bin) when is_bitstring(bin) do
    :crypto.hash(:sha256, bin)
  end

  @doc """
  Decodes a bech32 item into its respective type, be it privkey, pubkey or note

  ## Examples
      iex> "npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6"
      ...> |> Nostr.Crypto.bech32_decode()
      {:pubkey, <<0x3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d::256>>}
  """
  @spec bech32_decode(binary()) :: {:pubkey, binary()} | {:error, binary()}
  def bech32_decode("npub" <> _ = bech32_pubkey) do
    case Bech32.decode(bech32_pubkey) do
      {:ok, "npub", pubkey} -> {:pubkey, pubkey}
      {:ok, _, _} -> {:error, "malformed bech32 public key"}
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  Decodes a bech32 item into its respective type, be it privkey, pubkey or note and outputs
  it in a hex string format

  ## Examples
      iex> "npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6"
      ...> |> Nostr.Crypto.bech32_decode_to_hex()
      {:pubkey, "3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d"}
  """
  @spec bech32_decode(binary()) :: {:pubkey, binary()} | {:error, binary()}
  def bech32_decode_to_hex("npub" <> _ = bech32_pubkey) do
    case bech32_decode(bech32_pubkey) do
      {type, pubkey} -> {type, Binary.to_hex(pubkey)}
      {:error, message} -> {:error, message}
    end
  end
end
