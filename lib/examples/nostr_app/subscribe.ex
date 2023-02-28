defmodule NostrApp.Subscribe do
  @moduledoc """
  Hiding the boilerplate code to subscribe to various event types
  """

  require Logger

  alias NostrBasics.Models.Note
  alias NostrBasics.Keys.{PublicKey, PrivateKey}

  alias Nostr.Client

  @spec to_profile(PublicKey.id()) :: :ok
  def to_profile(public_key) do
    case Client.subscribe_profile(public_key) do
      {:ok, _} -> Logger.info("Subscribed to a profile")
      {:error, message} -> Logger.warn("#{inspect(message)}")
    end
  end

  @spec to_recommended_servers() :: :ok
  def to_recommended_servers() do
    Client.subscribe_recommended_servers()
    Logger.info("Subscribed to recommended servers")
  end

  @spec to_contacts(PublicKey.id()) :: :ok
  def to_contacts(public_key) do
    case Client.subscribe_contacts(public_key) do
      {:ok, _} -> Logger.info("Subscribed to a contact list")
      {:error, message} -> Logger.warn("#{inspect(message)}")
    end
  end

  @spec to_note(Note.id()) :: :ok
  def to_note(note_id) do
    case Client.subscribe_note(note_id) do
      {:ok, _} -> Logger.info("Subscribed to a note")
      {:error, message} -> Logger.warn("#{inspect(message)}")
    end
  end

  @spec to_kinds(list()) :: :ok
  def to_kinds(kinds) when is_list(kinds) do
    case Client.subscribe_kinds(kinds) do
      {:ok, _} -> Logger.info("Subscribed to kind #{kinds} notes")
      {:error, message} -> Logger.warn("#{inspect(message)}")
    end
  end

  @spec to_notes(list(PublicKey.id())) :: :ok
  def to_notes(public_keys) do
    case Client.subscribe_notes(public_keys) do
      {:ok, _} -> Logger.info("Subscribed to notes from: #{inspect(public_keys)}")
      {:error, message} -> Logger.warn("#{inspect(message)}")
    end
  end

  @spec to_encrypted_direct_messages(PrivateKey.id()) :: :ok
  def to_encrypted_direct_messages(private_key) do
    case Client.encrypted_direct_messages(private_key) do
      {:ok, _} -> Logger.info("Subscribed to #{inspect(private_key)}'s encrypted messages")
      {:error, message} -> Logger.warn("#{inspect(message)}")
    end
  end

  @spec to_reactions(list(PublicKey.id())) :: :ok
  def to_reactions(public_keys) do
    case Client.subscribe_reactions(public_keys) do
      {:ok, _} -> Logger.info("Subscribed to #{inspect(public_keys)}'s reactions")
      {:error, message} -> Logger.warn("#{inspect(message)}")
    end
  end

  @spec to_deletions(list(PublicKey.id())) :: :ok
  def to_deletions(public_keys) do
    case Client.subscribe_deletions(public_keys) do
      {:ok, _} -> Logger.info("Subscribed to #{inspect(public_keys)}'s deletions")
      {:error, message} -> Logger.warn("#{inspect(message)}")
    end
  end

  @spec to_reposts(list(PublicKey.id())) :: :ok
  def to_reposts(public_keys) do
    case Client.subscribe_reposts(public_keys) do
      {:ok, _} -> Logger.info("Subscribed to #{inspect(public_keys)}'s reposts")
      {:error, message} -> Logger.warn("#{inspect(message)}")
    end
  end

  @spec to_timeline(PublicKey.id()) :: :ok
  def to_timeline(public_key) do
    case Client.subscribe_timeline(public_key) do
      {:ok, _} -> Logger.info("Subscribed to #{inspect(public_key)}'s timeline")
      {:error, message} -> Logger.warn("#{inspect(message)}")
    end
  end
end
