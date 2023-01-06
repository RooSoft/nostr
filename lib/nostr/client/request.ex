defmodule Nostr.Client.Request do
  alias Nostr.Util

  def profile(pubkey) do
    get([pubkey], [0])
  end

  def contacts(pubkey) do
    get([pubkey], [3])
  end

  def notes(pubkeys) when is_list(pubkeys) do
    get(pubkeys, [1])
  end

  def get(pubkeys, kinds) do
    id = Util.generate_random_id()
    json = request(id, pubkeys, kinds)

    {id, json}
  end

  def request(id, pubkeys, kinds) do
    hex_pubkeys = Enum.map(pubkeys, &Binary.to_hex(&1))

    [
      "REQ",
      id,
      %{
        authors: hex_pubkeys,
        kinds: kinds
      }
    ]
    |> Jason.encode!()
  end
end
