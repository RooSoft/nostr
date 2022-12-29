defmodule Nostr.Event.Types.BoostEvent do
  require Logger

  defstruct event: %Nostr.Event{}

  alias Nostr.Event
  alias Nostr.Event.Types.BoostEvent

  @kind 6

  def parse(body) do
    %{
      "content" => json_content,
      "created_at" => unix_created_at,
      "id" => id,
      "kind" => @kind,
      "pubkey" => hex_pubkey,
      "sig" => hex_sig,
      "tags" => tags
    } = body

    pubkey = Binary.from_hex(hex_pubkey)
    sig = Binary.from_hex(hex_sig)

    created_at =
      case DateTime.from_unix(unix_created_at) do
        {:ok, created_at} -> created_at
        {:error, _message} -> nil
      end

    content =
      case Jason.decode(json_content) do
        {:ok, content} -> content
        {:error, _} -> nil
      end

    %BoostEvent{
      event: %Event{
        id: id,
        content: content,
        created_at: created_at,
        kind: @kind,
        pubkey: pubkey,
        sig: sig,
        tags: tags
      }
    }
  end
end
