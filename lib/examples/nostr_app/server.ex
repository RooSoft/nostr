defmodule NostrApp.Server do
  @moduledoc """
  The server part of the NostrApp, which is an example of an app
  """

  use GenServer

  require Logger

  alias NostrApp.{ConsoleHandler, Subscribe}

  alias NostrBasics.Keys.{PrivateKey, PublicKey}
  alias NostrBasics.Models.{Profile}

  alias Nostr.Client

  @impl true
  def init(%{relays: relays, private_key: private_key} = args) do
    with {:ok, binary_private_key} <- PrivateKey.to_binary(private_key),
         {:ok, public_key} <- PublicKey.from_private_key(binary_private_key),
         {:ok, supervisor_pid} <- Nostr.Client.start_link() do
      connect_to_relays(relays)

      {
        :ok,
        %{args | private_key: binary_private_key}
        |> Map.put(:supervisor_pid, supervisor_pid)
        |> Map.put(:public_key, public_key)
      }
    else
      {:error, message} ->
        {:stop, {:shutdown, message}}

      :already_present ->
        :ok

      :ignore ->
        {:stop, {:shutdown, :ignore}}

      other ->
        {:stop, {:shutdown, other}}
    end
  end

  @impl true
  def handle_cast({:subscriptions}, socket) do
    subscriptions = Client.subscriptions()

    Logger.info("Subscribed to #{inspect(subscriptions)}")

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:unsubscribe, pid}, socket) do
    Client.unsubscribe(pid)

    {:noreply, socket}
  end

  ### Send functions
  ##################

  @impl true
  def handle_cast({:update_profile, %Profile{} = profile}, %{private_key: private_key} = socket) do
    Client.update_profile(profile, private_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:send_note, note}, %{private_key: private_key} = socket) do
    case Client.send_note(note, private_key) do
      :ok -> Logger.info("sent a note creation command")
      {:error, message} -> Logger.error(message)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:react, note_id}, %{private_key: private_key} = socket) do
    case Client.react(note_id, private_key) do
      {:ok, _} -> Logger.info("sent an reaction command")
      {:error, message} -> Logger.error(message)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:follow, contact_pubkey}, %{private_key: private_key} = socket) do
    case Client.follow(contact_pubkey, private_key) do
      {:ok, _} -> Logger.info("sent an follow command for #{contact_pubkey}")
      {:error, message} -> Logger.error(message)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:unfollow, contact_pubkey}, %{private_key: private_key} = socket) do
    case Client.unfollow(contact_pubkey, private_key) do
      {:ok, _} -> Logger.info("sent an unfollow command for #{contact_pubkey}")
      {:error, message} -> Logger.error(message)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_cast(
        {:send_encrypted_direct_messages, pubkey, message},
        %{private_key: private_key} = socket
      ) do
    case Client.send_encrypted_direct_messages(pubkey, message, private_key) do
      :ok -> Logger.info("sent an encrypted direct message command")
      {:error, message} -> Logger.error(message)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:delete, event_ids, note}, %{private_key: private_key} = socket) do
    case Client.delete_events(event_ids, note, private_key) do
      {:ok, _} -> Logger.info("sent a deletion command for #{inspect(event_ids)}")
      {:error, message} -> Logger.error(message)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:repost, note_id}, %{private_key: private_key} = socket) do
    case Client.repost(note_id, private_key) do
      {:ok, _} -> Logger.info("sent a repost command for #{note_id}")
      {:error, message} -> Logger.error(message)
    end

    {:noreply, socket}
  end

  ## Subscription functions
  #########################

  @impl true
  def handle_cast({:contacts}, %{public_key: public_key} = socket) do
    Subscribe.to_contacts(public_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:contacts, pubkey}, socket) do
    Subscribe.to_contacts(pubkey)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:encrypted_direct_messages}, %{private_key: private_key} = socket) do
    Subscribe.to_encrypted_direct_messages(private_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:encrypted_direct_messages, private_key}, socket) do
    Subscribe.to_encrypted_direct_messages(private_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:profile, nil}, %{public_key: public_key} = socket) do
    Subscribe.to_profile(public_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:recommended_servers}, socket) do
    Subscribe.to_recommended_servers()

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:profile, public_key}, socket) do
    Subscribe.to_profile(public_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:note, note_id}, socket) do
    Subscribe.to_note(note_id)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:notes}, %{public_key: public_key} = socket) do
    Subscribe.to_notes([public_key])

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:notes, pubkeys}, socket) do
    Subscribe.to_notes(pubkeys)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:deletions}, %{public_key: public_key} = socket) do
    Subscribe.to_deletions([public_key])

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:deletions, pubkeys}, socket) do
    Subscribe.to_deletions(pubkeys)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:reposts}, %{public_key: public_key} = socket) do
    Subscribe.to_reposts([public_key])

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:reposts, pubkeys}, socket) do
    Subscribe.to_reposts(pubkeys)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:reactions}, %{public_key: public_key} = socket) do
    Subscribe.to_reactions([public_key])

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:reactions, pubkeys}, socket) do
    Subscribe.to_reactions(pubkeys)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:timeline}, %{public_key: public_key} = socket) do
    Subscribe.to_timeline(public_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:timeline, pubkey}, socket) do
    Subscribe.to_timeline(pubkey)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:console, type, message}, socket) do
    ConsoleHandler.handle(type, message)

    {:noreply, socket}
  end

  @impl true
  def handle_info({relay, event}, socket) do
    # credo:disable-for-next-line
    IO.puts("from #{relay}")
    # credo:disable-for-next-line
    IO.inspect(event)

    {:noreply, socket}
  end

  @impl true
  def handle_info(event, socket) do
    # credo:disable-for-next-line
    IO.inspect(event)

    {:noreply, socket}
  end

  defp connect_to_relays(relays) do
    for relay <- relays do
      Client.add_relay(relay)
    end
  end
end
