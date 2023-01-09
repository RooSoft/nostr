defmodule Nostr.Client.Request do
  alias Nostr.Util

  def profile(pubkey) do
    get([pubkey], [0], nil)
  end

  def contacts(pubkey, limit) do
    get([pubkey], [3], limit)
  end

  def notes(pubkeys, limit \\ 10) when is_list(pubkeys) do
    get(pubkeys, [1], limit)
  end

  def reactions(pubkeys, limit \\ 10) when is_list(pubkeys) do
    get(pubkeys, [7], limit)
  end

  defp get(pubkeys, kinds, limit) do
    id = Util.generate_random_id()
    filter = filter(pubkeys, kinds, limit)
    json = request(id, filter)

    {id, json}
  end

  defp filter(pubkeys, kinds, limit) when is_integer(limit) do
    hex_pubkeys = Enum.map(pubkeys, &Binary.to_hex(&1))

    %{
      authors: hex_pubkeys,
      kinds: kinds,
      limit: limit
    }
  end

  defp filter(pubkeys, kinds, _) do
    hex_pubkeys = Enum.map(pubkeys, &Binary.to_hex(&1))

    %{
      authors: hex_pubkeys,
      kinds: kinds
    }
  end

  defp request(id, filter) do
    ["REQ", id, filter]
    |> Jason.encode!()
  end
end
