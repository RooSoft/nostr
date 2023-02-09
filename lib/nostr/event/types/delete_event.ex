defmodule Nostr.Event.Types.DeleteEvent do
  @moduledoc """
  Delete event management, including event creation and parsing

  A delete event doen't delete anything, it's an event that might end up
  masking another one, hence the "creation of a delete event"
  """

  require Logger

  alias NostrBasics.Event
  alias Nostr.Event.Types.{DeleteEvent}

  defstruct event: %Event{}

  @kind 5

  def create_event(event_ids, note, pubkey) do
    tags =
      event_ids
      |> Enum.map(&["e", Binary.to_hex(&1)])

    %{
      Event.create(@kind, note, pubkey)
      | tags: tags,
        created_at: DateTime.utc_now()
    }
    |> Event.add_id()
  end

  def parse(body) do
    event = Event.parse(body)

    case event.kind do
      @kind -> {:ok, %DeleteEvent{event: event}}
      kind -> {:error, "Tried to parse a deletion event with kind #{kind} instead of #{@kind}"}
    end
  end
end
