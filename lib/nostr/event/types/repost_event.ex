defmodule Nostr.Event.Types.RepostEvent do
  require Logger

  defstruct event: %Nostr.Event{}

  alias Nostr.Keys.PublicKey
  alias Nostr.Event
  alias Nostr.Event.Types.{RepostEvent, TextEvent}

  @kind 6
  @text_event_kind 1

  def create_event(
        %TextEvent{event: %Event{id: note_id, pubkey: note_pubkey}} = text_event,
        pubkey,
        relays
      ) do
    tags = [
      ["e", note_id],
      ["p", note_pubkey |> Binary.to_hex()]
    ]

    content = content_from_text_event(text_event, relays)

    %{
      Event.create(content, pubkey)
      | kind: @kind,
        tags: tags,
        created_at: DateTime.utc_now()
    }
    |> Event.add_id()
  end

  @spec parse(map()) :: {:ok, %RepostEvent{}} | {:error, binary()}
  def parse(body) do
    event = Event.parse(body)

    case event.kind do
      @kind -> {:ok, %RepostEvent{event: event}}
      kind -> {:error, "Tried to parse a repost event with kind #{kind} instead of #{@kind}"}
    end
  end

  defp content_from_text_event(%TextEvent{event: %Event{} = event}, relays) do
    %{
      content: event.content,
      created_at: event.created_at,
      id: event.id,
      kind: @text_event_kind,
      pubkey: event.pubkey |> Binary.to_hex(),
      relays: relays,
      sig: event.sig |> Binary.to_hex(),
      tags: event.tags
    }
    |> Jason.encode!()
  end
end
