defmodule Nostr.Event.EncryptedDirectMessageEvent do
  require Logger

  defstruct [:content, :tags, :created_at]

  alias Nostr.Event.EncryptedDirectMessageEvent

  def parse(body) do
    %{
      "content" => content,
      "created_at" => unix_timestamp,
      "id" => _id,
      "kind" => 4,
      "pubkey" => _pubkey,
      "sig" => _sig,
      "tags" => tags
    } = body

    with {:ok, created_at} <- DateTime.from_unix(unix_timestamp) do
      %EncryptedDirectMessageEvent{content: content, tags: tags, created_at: created_at}
    else
      {:error, _message} ->
        %EncryptedDirectMessageEvent{}
    end
  end
end
