defmodule Nostr.Event.Types.RepostEvent do
  @moduledoc """
  Repost event management, including event creation and parsing

  Note that this kind of event has been officially removed by fiatjaf from
  the official specification, so kind 6 doesn't exist anymore at the moment
  of this writing. Clients are still using it so it will remain by the time
  being.
  """

  require Logger

  defstruct event: %Nostr.Event{}

  alias Nostr.Event
  alias Nostr.Event.Types.{RepostEvent, TextEvent}

  @type t :: %RepostEvent{}

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

  @spec parse(map()) :: {:ok, RepostEvent.t()} | {:error, binary()}
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
      created_at: event.created_at |> DateTime.to_unix(),
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
