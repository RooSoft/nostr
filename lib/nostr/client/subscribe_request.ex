defmodule Nostr.Client.SubscribeRequest do
  alias Nostr.Util

  def author(pubkey, limit \\ 10) do
    id = Util.generate_random_id()
    json = request(id, pubkey, limit)

    {id, json}
  end

  def request(id, pubkey, limit) do
    hex_pubkey = Binary.to_hex(pubkey)

    [
      "REQ",
      id,
      %{
        authors: [hex_pubkey],
        limit: limit
      }
    ]
    |> Jason.encode!()
  end
end
