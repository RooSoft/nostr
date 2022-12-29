defmodule Nostr.Event.Types.ReactionEvent do
  require Logger

  defstruct event: %Nostr.Event{}

  alias Nostr.Event
  alias Nostr.Event.Types.ReactionEvent

  @kind 7

  def parse(body) do
    event = Event.parse(body)

    case event.kind do
      @kind -> {:ok, %ReactionEvent{event: event}}
      kind -> {:error, "Tried to parse a reaction event with kind #{kind} instead of #{@kind}"}
    end
  end
end
