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
end
