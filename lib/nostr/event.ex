defmodule Nostr.Event do
  @moduledoc """
  Represents the basic structure of anything that's being sent to/from relays
  """

  require Logger

  defstruct [:id, :pubkey, :created_at, :kind, :tags, :content, :sig]

  alias Nostr.Event
  alias Nostr.Crypto

  # This thing is needed so that the Jason library knows how to serialize the events
  defimpl Jason.Encoder do
    def encode(
          %Event{
            id: id,
            pubkey: pubkey,
            created_at: created_at,
            kind: kind,
            sig: sig,
            tags: _tags,
            content: content
          },
          opts
        ) do
      hex_pubkey = Binary.to_hex(pubkey)
      hex_sig = Binary.to_hex(sig)
      timestamp = DateTime.to_unix(created_at)

      Jason.Encode.map(
        %{
          "id" => id,
          "pubkey" => hex_pubkey,
          "created_at" => timestamp,
          "kind" => kind,
          "tags" => [],
          "content" => content,
          "sig" => hex_sig
        },
        opts
      )
    end
  end

  @doc """
  Simplifies the creation of an event, adding the created_at and tags fields and
  requiring the bare minimum to do so

  ## Examples
      iex> now = DateTime.utc_now()
      ...> pubkey = <<0xEFC83F01C8FB309DF2C8866B8C7924CC8B6F0580AFDDE1D6E16E2B6107C2862C::256>>
      ...> event = Nostr.Event.create("this is the content", pubkey)
      ...> %{event | created_at: now}
      %Nostr.Event{
        id: nil,
        pubkey: <<0xefc83f01c8fb309df2c8866b8c7924cc8b6f0580afdde1d6e16e2b6107c2862c::256>>,
        kind: nil,
        created_at: now,
        tags: [],
        content: "this is the content",
        sig: nil
      }
  """
  @spec create(binary(), <<_::256>>) :: %Event{}
  def create(content, <<_::256>> = pubkey) do
    %Event{
      pubkey: pubkey,
      created_at: DateTime.utc_now(),
      tags: [],
      content: content
    }
  end

  def add_id(event) do
    id = create_id(event)

    %{event | id: id}
  end

  def create_id(%Event{} = event) do
    event
    |> json_for_id()
    |> Crypto.sha256()
    |> Binary.to_hex()
  end

  def json_for_id(%Event{
        pubkey: pubkey,
        created_at: created_at,
        kind: kind,
        tags: tags,
        content: content
      }) do
    hex_pubkey = Binary.to_hex(pubkey)
    timestamp = DateTime.to_unix(created_at)

    [
      0,
      hex_pubkey,
      timestamp,
      kind,
      tags,
      content
    ]
    |> Jason.encode!()
  end
end
