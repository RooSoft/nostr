defmodule Nostr.Util do
  @default_size 16

  @doc """
  Generates a random hex string composed of size*2 characters

  ## Examples
      iex> Nostr.Util.generate_random_id(16)
  """
  @spec generate_random_id(integer()) :: binary()
  def generate_random_id(size \\ @default_size) do
    :crypto.strong_rand_bytes(size) |> Binary.to_hex()
  end
end
