defmodule Nostr.Crypto do
  @doc """
  Computes [SHA256](https://en.wikipedia.org/wiki/SHA-2) on a binary and returns it as a binary
  ## Examples
      iex> "6c7ab2f961a1bc3f13cdc08dc41c3f439adebd549a8ef1c089e81a5907376107"
      ...> |> Nostr.Crypto.sha256()
      <<0xab6a8f1d9e2b0333dff8e370ed6fdfe20b2e8008e045efb3fb3298c22f7569da::256>>
  """
  @spec sha256(String.t()) :: <<_::256>>
  def sha256(bin) when is_bitstring(bin) do
    :crypto.hash(:sha256, bin)
  end
end
