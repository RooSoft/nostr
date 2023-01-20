defmodule NostrApp.Subscribe do
  require Logger

  alias Nostr.Client

  def to_profile(public_key) do
    case Client.subscribe_profile(public_key) do
      {:ok, _} -> Logger.info("Subscribed to #{public_key}'s profile")
      {:error, message} -> Logger.warn(message)
    end
  end

  def to_note(note_id) do
    case Client.subscribe_note(note_id) do
      {:ok, _} -> Logger.info("Subscribed to this note: #{note_id}")
      {:error, message} -> Logger.warn(message)
    end
  end
end
