defmodule Nostr.Event.Types.MetadataEvent do
  @moduledoc """
  Metadata event management, including event creation and parsing

  This represents mainly a user's profile at the time of this writing
  """

  require Logger

  alias NostrBasics.Event
  alias Nostr.Models.Profile
  alias Nostr.Event.Types.MetadataEvent

  defstruct event: %Event{}

  @kind 0

  @spec create_empty_event(<<_::256>>) :: Event.t()
  def create_empty_event(pubkey) do
    %{
      Event.create(@kind, nil, pubkey)
      | tags: [],
        created_at: DateTime.utc_now()
    }
    |> Event.add_id()
  end

  @spec create_event(Profile.t(), <<_::256>>) ::
          {:ok, Event.t()} | {:error, binary()}
  def create_event(%Profile{} = profile, pubkey) do
    case Jason.encode(profile) do
      {:ok, json_profile} ->
        event =
          %{
            Event.create(@kind, json_profile, pubkey)
            | tags: [],
              created_at: DateTime.utc_now()
          }
          |> Event.add_id()

        {:ok, event}

      {:error, message} ->
        {:error, message}
    end
  end

  def parse(body) do
    event = Event.parse(body)

    case event.kind do
      @kind -> {:ok, %MetadataEvent{event: event}}
      kind -> {:error, "Tried to parse a metadata event with kind #{kind} instead of #{@kind}"}
    end
  end
end
