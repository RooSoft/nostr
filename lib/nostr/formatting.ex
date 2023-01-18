defmodule Nostr.Formatting do
  @moduledoc """
  Converting computer stuff into other stuff humans can understand
  """

  @doc """
  Converts a binary into a hex formatted string

  ## Examples
      iex> <<0xab6a8f1d9e2b0333dff8e370ed6fdfe20b2e8008e045efb3fb3298c22f7569da::256>>
      ...> |> Nostr.Formatting.to_hex()
      "ab6a8f1d9e2b0333dff8e370ed6fdfe20b2e8008e045efb3fb3298c22f7569da"
  """
  @spec to_hex(binary()) :: String.t()
  def to_hex(nil), do: nil

  def to_hex(binary) do
    binary
    |> Binary.to_hex()
  end
end
