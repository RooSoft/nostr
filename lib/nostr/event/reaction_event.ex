defmodule Nostr.Event.ReactionEvent do
  require Logger

  defstruct event: %Nostr.Event{}

  alias Nostr.Event
  alias Nostr.Event.ReactionEvent

  @kind 7

  def parse(content) do
    %{
      "content" => content,
      "created_at" => unix_created_at,
      "id" => id,
      "kind" => @kind,
      "pubkey" => pubkey,
      "sig" => sig,
      "tags" => tags
    } = content

    with {:ok, created_at} <- DateTime.from_unix(unix_created_at) do
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
    else
      {:error, _message} ->
        %ReactionEvent{
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
