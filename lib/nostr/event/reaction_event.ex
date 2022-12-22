defmodule Nostr.Event.ReactionEvent do
  require Logger

  defstruct [:id, :pubkey, :sig, :created_at]

  alias Nostr.Event.ReactionEvent

  def parse(content) do
    %{
      "content" => _content,
      "created_at" => unix_created_at,
      "id" => id,
      "kind" => 7,
      "pubkey" => pubkey,
      "sig" => sig,
      "tags" => _tags
    } = content

    with {:ok, created_at} <- DateTime.from_unix(unix_created_at) do
      %ReactionEvent{id: id, pubkey: pubkey, sig: sig, created_at: created_at}
    else
      {:error, _message} ->
        %ReactionEvent{pubkey: pubkey}
    end
  end
end
