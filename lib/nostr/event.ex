defmodule Nostr.Event do
  require Logger

  defstruct [:id, :pubkey, :created_at, :kind, :tags, :content, :sig]

  alias Nostr.Event
  alias Nostr.Crypto

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

  def create(pubkey, content) do
    %Event{
      pubkey: pubkey,
      created_at: DateTime.now!("Etc/UTC"),
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
