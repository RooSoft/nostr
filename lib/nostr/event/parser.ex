defmodule Nostr.Event.Parser do
  @moduledoc """
  Turns raw events from JSON websocket messages into elixir structs
  """

  alias Nostr.Event

  def parse(%{
        "content" => json_content,
        "created_at" => unix_created_at,
        "id" => id,
        "kind" => kind,
        "pubkey" => hex_pubkey,
        "sig" => hex_sig,
        "tags" => tags
      }) do
    pubkey = Binary.from_hex(hex_pubkey)
    sig = Binary.from_hex(hex_sig)

    created_at = parse_created_at(unix_created_at)
    content = parse_content(json_content)

    %Event{
      id: id,
      content: content,
      created_at: created_at,
      kind: kind,
      pubkey: pubkey,
      sig: sig,
      tags: tags
    }
  end

  defp parse_created_at(unix_created_at) do
    case DateTime.from_unix(unix_created_at) do
      {:ok, created_at} -> created_at
      {:error, _message} -> nil
    end
  end

  defp parse_content(json_content) do
    case Jason.decode(json_content) do
      {:ok, content} -> content
      {:error, _} -> nil
    end
  end
end
