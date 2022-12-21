defmodule Nostr.Client.Event.Reaction do
  require Logger

  def parse(content) do
    %{
      "content" => _content,
      "created_at" => created_at,
      "id" => _id,
      "kind" => 7,
      "pubkey" => _pub_key,
      "sig" => _signature,
      "tags" => _tags
    } = content

    with {:ok, time} <- DateTime.from_unix(created_at) do
      Logger.info("7- reaction: #{time}")
    else
      {:error, message} ->
        Logger.warning("Can't parse time: #{message}")
    end
  end
end
