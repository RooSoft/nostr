defmodule Nostr.Event.Types.BoostEvent do
  require Logger

  defstruct event: %Nostr.Event{}

  alias Nostr.Event
  alias Nostr.Event.Types.BoostEvent

  @kind 6

  @spec parse(map()) :: {:ok, %BoostEvent{}} | {:error, binary()}
  def parse(body) do
    event = Event.parse(body)

    case event.kind do
      @kind -> {:ok, %BoostEvent{event: event}}
      kind -> {:error, "Tried to parse a boost event with kind #{kind} instead of #{@kind}"}
    end
  end
end
