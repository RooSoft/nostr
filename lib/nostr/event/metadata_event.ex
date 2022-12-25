defmodule Nostr.Event.MetadataEvent do
  require Logger

  defstruct event: %Nostr.Event{}

  alias Nostr.Event
  alias Nostr.Event.MetadataEvent

  @kind 0

  def parse(content) do
    %{
      # according to NIP-02, should be ignored
      "content" => _content,
      "created_at" => unix_created_at,
      "id" => id,
      "kind" => 0,
      "pubkey" => pubkey,
      "sig" => sig,
      "tags" => tags
    } = content

    with {:ok, created_at} <- DateTime.from_unix(unix_created_at) do
      %MetadataEvent{
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
        %MetadataEvent{
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
