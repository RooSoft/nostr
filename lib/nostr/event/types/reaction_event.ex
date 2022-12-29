defmodule Nostr.Event.Types.ReactionEvent do
  require Logger

  defstruct event: %Nostr.Event{}

  alias Nostr.Event
  alias Nostr.Event.Types.ReactionEvent

  @kind 7

  def parse(content) do
    %{
      "content" => content,
      "created_at" => unix_created_at,
      "id" => id,
      "kind" => @kind,
      "pubkey" => hex_pubkey,
      "sig" => hex_sig,
      "tags" => tags
    } = content

    pubkey = Binary.from_hex(hex_pubkey)
    sig = Binary.from_hex(hex_sig)

    created_at =
      case DateTime.from_unix(unix_created_at) do
        {:ok, created_at} -> created_at
        {:error, _} -> nil
      end

    %ReactionEvent{
      event: %Event{
        id: id,
        pubkey: pubkey,
        created_at: created_at,
        kind: @kind,
        sig: sig,
        tags: tags,
        content: content
      }
    }
  end
end
