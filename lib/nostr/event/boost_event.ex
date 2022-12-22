defmodule Nostr.Event.BoostEvent do
  require Logger

  defstruct [:content, :tags, :created_at]

  alias Nostr.Event.BoostEvent

  def parse(body) do
    %{
      "content" => json_content,
      "created_at" => unix_created_at,
      "id" => _id,
      "kind" => 6,
      "pubkey" => _pubkey,
      "sig" => _sig,
      "tags" => tags
    } = body

    with {:ok, content} <- Jason.decode(json_content),
         {:ok, created_at} <- DateTime.from_unix(unix_created_at) do
      %BoostEvent{content: content, created_at: created_at, tags: tags}
    else
      {:error, _message} -> %BoostEvent{}
    end
  end
end