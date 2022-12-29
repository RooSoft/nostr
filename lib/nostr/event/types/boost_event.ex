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

    with {:ok, content} <- Jason.decode(json_content),
         {:ok, created_at} <- DateTime.from_unix(unix_created_at) do
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
    else
      {:error, _message} ->
        %BoostEvent{
          event: %Event{
            id: id,
            kind: @kind,
            pubkey: pubkey,
            sig: sig,
            tags: tags
          }
        }
    end
  end
end
