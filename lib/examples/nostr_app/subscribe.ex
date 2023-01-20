defmodule NostrApp.Subscribe do
  require Logger

  alias Nostr.Client

  def to_profile(public_key) do
    case Client.subscribe_profile(public_key) do
      {:ok, _} -> Logger.info("Subscribed to #{public_key}'s profile")
      {:error, message} -> Logger.warn(message)
    end
  end
end
