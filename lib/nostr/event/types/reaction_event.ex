defmodule Nostr.Event.Types.ReactionEvent do
  @moduledoc """
  Reaction event management, including event creation and parsing

  This thing is similar to a Facebook or Twitter like
  """

  require Logger

  alias NostrBasics.Event
  alias Nostr.Event.Types.{TextEvent, ReactionEvent}

  defstruct event: %Event{}

  @kind 7

  def create_event(%TextEvent{event: %Event{id: note_id, pubkey: note_pubkey}}, content, pubkey) do
    tags = [
      ["e", note_id],
      ["p", note_pubkey |> Binary.to_hex()]
    ]

    %{
      Event.create(@kind, content, pubkey)
      | tags: tags,
        created_at: DateTime.utc_now()
    }
    |> Event.add_id()
  end

  def parse(body) do
    event = Event.parse(body)

    case event.kind do
      @kind -> {:ok, %ReactionEvent{event: event}}
      kind -> {:error, "Tried to parse a reaction event with kind #{kind} instead of #{@kind}"}
    end
  end
end
