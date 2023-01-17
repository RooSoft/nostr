defmodule Nostr.Client.Request do
  alias Nostr.Util

  @metadata_kind 0
  @text_kind 1
  @contacts_kind 3
  @encrypted_direct_message_kind 4
  @deletion_kind 5
  @repost_kind 6
  @reaction_kind 7

  def profile(pubkey) do
    get_by_authors([pubkey], [@metadata_kind], nil)
  end

  def contacts(pubkey, limit) do
    get_by_authors([pubkey], [@contacts_kind], limit)
  end

  def note(id) do
    get_by_ids([id], @text_kind)
  end

  def notes(pubkeys, limit \\ 10) when is_list(pubkeys) do
    get_by_authors(pubkeys, [@text_kind], limit)
  end

  def deletions(pubkeys, limit \\ 10) when is_list(pubkeys) do
    get_by_authors(pubkeys, [@deletion_kind], limit)
  end

  def reposts(pubkeys, limit \\ 10) when is_list(pubkeys) do
    get_by_authors(pubkeys, [@repost_kind], limit)
  end

  def reactions(pubkeys, limit \\ 10) when is_list(pubkeys) do
    get_by_authors(pubkeys, [@reaction_kind], limit)
  end

  def encrypted_direct_messages(<<_::256>> = pubkey, limit \\ 10) do
    tags = [pubkey |> Binary.to_hex()]
    get_by_kind(@encrypted_direct_message_kind, tags, limit)
  end

  defp get_by_kind(kind, pubkeys, limit) do
    request_id = Util.generate_random_id()
    filter = filter_by_kind(kind, pubkeys, limit)
    json = request(request_id, filter)

    {request_id, json}
  end

  defp get_by_ids(ids, kind) do
    request_id = Util.generate_random_id()
    filter = filter_by_ids(ids, kind, 1)
    json = request(request_id, filter)

    {request_id, json}
  end

  defp get_by_authors(pubkeys, kinds, limit) do
    request_id = Util.generate_random_id()
    filter = filter_by_authors(pubkeys, kinds, limit)
    json = request(request_id, filter)

    {request_id, json}
  end

  defp filter_by_kind(kind, pubkeys, limit) do
    %{
      kinds: [kind],
      "#p": pubkeys,
      limit: limit
    }
  end

  defp filter_by_ids(ids, kind, limit) do
    hex_ids = Enum.map(ids, &Binary.to_hex(&1))

    %{
      ids: hex_ids,
      kinds: [kind],
      limit: limit
    }
  end

  defp filter_by_authors(pubkeys, kinds, limit) when is_integer(limit) do
    hex_pubkeys = Enum.map(pubkeys, &Binary.to_hex(&1))

    %{
      authors: hex_pubkeys,
      kinds: kinds,
      limit: limit
    }
  end

  defp filter_by_authors(pubkeys, kinds, _) do
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
