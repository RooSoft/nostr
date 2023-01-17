defmodule Nostr.Event.Types.DeleteEvent do
  require Logger

  defstruct event: %Nostr.Event{}

  alias Nostr.Event
  alias Nostr.Event.Types.{DeleteEvent}

  @kind 5

  def create_event(event_ids, note, pubkey) do
    tags =
      event_ids
      |> Enum.map(&["e", Binary.to_hex(&1)])

    %{
      Event.create(note, pubkey)
      | kind: @kind,
        tags: tags,
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