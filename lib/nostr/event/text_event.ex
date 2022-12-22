defmodule Nostr.Event.TextEvent do
  require Logger

  defstruct [:content, :tags, :created_at]

  alias Nostr.Event.TextEvent

  def parse(body) do
    %{
      "content" => content,
      "created_at" => unix_timestamp,
      "id" => _id,
      "kind" => 1,
      "pubkey" => _pubkey,
      "sig" => _sig,
      "tags" => tags
    } = body

    with {:ok, created_at} <- DateTime.from_unix(unix_timestamp) do
      %TextEvent{content: content, tags: tags, created_at: created_at}
    else
      {:error, _message} ->
        %TextEvent{}
    end
  end
end
