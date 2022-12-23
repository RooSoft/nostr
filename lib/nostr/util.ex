defmodule Nostr.Util do
  def generate_random_id() do
    :crypto.strong_rand_bytes(16) |> Binary.to_hex()
  end
end
