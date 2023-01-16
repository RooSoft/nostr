defmodule Nostr.Event.Types.RepostEvent do
  require Logger

  defstruct event: %Nostr.Event{}

  alias Nostr.Event
  alias Nostr.Event.Types.RepostEvent

  @kind 6

  @spec parse(map()) :: {:ok, %RepostEvent{}} | {:error, binary()}
  def parse(body) do
    event = Event.parse(body)

    case event.kind do
      @kind -> {:ok, %RepostEvent{event: event}}
      kind -> {:error, "Tried to parse a repost event with kind #{kind} instead of #{@kind}"}
    end
  end
end
