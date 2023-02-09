defmodule Nostr.Event.Types.RecommendedServerEvent do
  @moduledoc """
  Recommended relays event management, including event creation and parsing

  This represents mainly a user's relay list at the time of this writing
  """

  alias NostrBasics.Event
  alias Nostr.Event.Types.RecommendedServerEvent

  defstruct [:relay, event: %Event{}]

  @kind 2

  @spec create_empty_event(<<_::256>>) :: Event.t()
  def create_empty_event(pubkey) do
    %{
      Event.create(@kind, nil, pubkey)
      | tags: [],
        created_at: DateTime.utc_now()
    }
    |> Event.add_id()
  end

  def parse(%{"content" => content} = body) do
    event = Event.parse(body)

    case event.kind do
      @kind ->
        {:ok, %RecommendedServerEvent{relay: content, event: event}}

      kind ->
        {:error,
         "Tried to parse a recommended servers event with kind #{kind} instead of #{@kind}"}
    end
  end
end
