defmodule Nostr.Event.ReactionEvent do
  require Logger

  defstruct [:created_at]

  alias Nostr.Event.ReactionEvent

  def parse(content) do
    %{
      "content" => _content,
      "created_at" => unix_created_at,
      "id" => _id,
      "kind" => 7,
      "pubkey" => _pub_key,
      "sig" => _signature,
      "tags" => _tags
    } = content

    with {:ok, created_at} <- DateTime.from_unix(unix_created_at) do
      %ReactionEvent{created_at: created_at}
    else
      {:error, _message} ->
        %ReactionEvent{}
    end
  end
end
