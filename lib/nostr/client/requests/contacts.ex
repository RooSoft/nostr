defmodule Nostr.Client.Requests.Contacts do
  alias Nostr.Util

  def get(pubkey) do
    id = Util.generate_random_id()
    json = request(id, pubkey)

    {id, json}
  end

  def request(id, pubkey) do
    hex_pubkey = Binary.to_hex(pubkey)

    [
      "REQ",
      id,
      %{
        authors: [hex_pubkey],
        kinds: [3]
      }
    ]
    |> Jason.encode!()
  end
end
