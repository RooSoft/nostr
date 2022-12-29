defmodule Nostr.Event.Types.MetadataEvent do
  require Logger

  defstruct event: %Nostr.Event{}

  alias Nostr.Event
  alias Nostr.Event.Types.MetadataEvent

  @kind 0

  def parse(body) do
    event = Event.parse(body)

    case event.kind do
      @kind -> {:ok, %MetadataEvent{event: event}}
      kind -> {:error, "Tried to parse a metadata event with kind #{kind} instead of #{@kind}"}
    end
  end
end
