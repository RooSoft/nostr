defmodule Nostr.Event.Types.EncryptedDirectMessageEvent do
  require Logger

  defstruct event: %Nostr.Event{}

  alias Nostr.Event
  alias Nostr.Event.Types.EncryptedDirectMessageEvent

  @kind 4

  def parse(%{"content" => content} = body) do
    event = %{Event.parse(body) | content: content}

    case event.kind do
      @kind ->
        {:ok, %EncryptedDirectMessageEvent{event: event}}

      kind ->
        {:error,
         "Tried to parse a encrypted direct message event with kind #{kind} instead of #{@kind}"}
    end
  end
end
