defmodule Nostr.Event.TextEvent do
  require Logger

  defstruct event: %Nostr.Event{}

  alias Nostr.Event
  alias Nostr.Event.TextEvent

  @kind 1

  def create(<<_::256>> = pubkey, content) do
    event =
      %{Event.create(pubkey, content) | kind: @kind}
      |> Event.add_id()

    %TextEvent{event: event}
  end

  def parse(body) do
    %{
      "content" => content,
      "created_at" => unix_timestamp,
      "id" => id,
      "kind" => @kind,
      "pubkey" => hex_pubkey,
      "sig" => hex_sig,
      "tags" => tags
    } = body

    pubkey = Binary.from_hex(hex_pubkey)
    sig = Binary.from_hex(hex_sig)

    with {:ok, created_at} <- DateTime.from_unix(unix_timestamp) do
      %TextEvent{
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
        %TextEvent{
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
