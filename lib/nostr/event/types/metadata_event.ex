defmodule Nostr.Event.Types.MetadataEvent do
  require Logger

  defstruct event: %Nostr.Event{}

  alias Nostr.Event
  alias Nostr.Models.Profile
  alias Nostr.Event.Types.MetadataEvent

  @kind 0

  @spec create_empty_event(K256.Schnorr.verifying_key() | <<_::256>>) :: Event.t()
  def create_empty_event(pubkey) do
    %{
      Event.create(nil, pubkey)
      | kind: @kind,
        tags: [],
        created_at: DateTime.utc_now()
    }
    |> Event.add_id()
  end

  @spec create_event(Profile.t(), K256.Schnorr.verifying_key() | <<_::256>>) ::
          {:ok, Event.t()} | {:error, binary()}
  def create_event(%Profile{} = profile, pubkey) do
    case Jason.encode(profile) do
      {:ok, json_profile} ->
        event =
          %{
            Event.create(json_profile, pubkey)
            | kind: @kind,
              tags: [],
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
