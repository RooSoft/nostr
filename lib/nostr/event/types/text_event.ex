defmodule Nostr.Event.Types.TextEvent do
  require Logger

  defstruct event: %Nostr.Event{}

  alias Nostr.Event
  alias Nostr.Event.Types.TextEvent

  @kind 1

  @spec create(binary(), K256.Schnorr.verifying_key()) :: %TextEvent{}
  def create(content, pubkey) do
    event =
      %{Event.create(content, pubkey) | kind: @kind}
      |> Event.add_id()

    %TextEvent{event: event}
  end

  def parse(%{"content" => content} = body) do
    event = %{Event.parse(body) | content: content}

    case event.kind do
      @kind -> {:ok, %TextEvent{event: event}}
      kind -> {:error, "Tried to parse a text event with kind #{kind} instead of #{@kind}"}
    end
  end
end
