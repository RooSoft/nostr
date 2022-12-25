defmodule Nostr.Event.EncryptedDirectMessageEvent do
  require Logger

  defstruct event: %Nostr.Event{}

  alias Nostr.Event
  alias Nostr.Event.EncryptedDirectMessageEvent

  @kind 4

  def parse(body) do
    %{
      "content" => content,
      "created_at" => unix_timestamp,
      "id" => id,
      "kind" => @kind,
      "pubkey" => pubkey,
      "sig" => sig,
      "tags" => tags
    } = body

    with {:ok, created_at} <- DateTime.from_unix(unix_timestamp) do
      %EncryptedDirectMessageEvent{
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
    else
      {:error, _message} ->
        %EncryptedDirectMessageEvent{
          event: %Event{
            id: id,
            pubkey: pubkey,
            kind: @kind,
            sig: sig,
            tags: tags,
            content: content
          }
        }
    end
  end
end
