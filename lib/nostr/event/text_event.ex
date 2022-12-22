defmodule Nostr.Event.TextEvent do
  require Logger

  defstruct [:id, :content, :tags, :pubkey, :sig, :created_at]

  alias Nostr.Event.TextEvent

  def parse(body) do
    %{
      "content" => content,
      "created_at" => unix_timestamp,
      "id" => id,
      "kind" => 1,
      "pubkey" => pubkey,
      "sig" => sig,
      "tags" => tags
    } = body

    with {:ok, created_at} <- DateTime.from_unix(unix_timestamp) do
      %TextEvent{
        id: id,
        content: content,
        tags: tags,
        pubkey: pubkey,
        sig: sig,
        created_at: created_at
      }
    else
      {:error, _message} ->
        %TextEvent{}
    end
  end
end
