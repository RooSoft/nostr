defmodule NostrApp.Server do
  @moduledoc """
  The server part of the NostrApp, which is an example of an app
  """

  use GenServer

  require Logger

  alias NostrApp.Subscribe

  alias Nostr.Client
  alias Nostr.Event.Types.MetadataEvent
  alias Nostr.Models.{Profile}

  @impl true
  def init(%{relays: relays, private_key: private_key} = args) do
    with {:ok, public_key} <- K256.Schnorr.verifying_key_from_signing_key(private_key),
         {:ok, supervisor_pid} <- Nostr.Client.start_link() do
      connect_to_relays(relays)

      {
        :ok,
        args
        |> Map.put(:supervisor_pid, supervisor_pid)
        |> Map.put(:public_key, public_key)
      }
    else
      {:error, message} ->
        {:stop, message}

      :already_present ->
        :ok

      :ignore ->
        {:stop, :ignore}

      other ->
        {:stop, other}
    end
  end

  @impl true
  def handle_cast({:send_note, note}, %{private_key: private_key} = socket) do
    Client.send_note(note, private_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:react, note_id}, %{private_key: private_key} = socket) do
    Client.react(note_id, private_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:contacts}, %{public_key: public_key} = socket) do
    Client.subscribe_contacts(public_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:contacts, pubkey}, socket) do
    Client.subscribe_contacts(pubkey)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:follow, contact_pubkey}, %{private_key: private_key} = socket) do
    Client.follow(contact_pubkey, private_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:unfollow, contact_pubkey}, %{private_key: private_key} = socket) do
    Client.unfollow(contact_pubkey, private_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:encrypted_direct_messages}, %{private_key: private_key} = socket) do
    Client.encrypted_direct_messages(private_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:encrypted_direct_messages, private_key}, socket) do
    Client.encrypted_direct_messages(private_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast(
        {:send_encrypted_direct_messages, pubkey, message},
        %{private_key: private_key} = socket
      ) do
    Client.send_encrypted_direct_messages(pubkey, message, private_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:profile, nil}, %{public_key: public_key} = socket) do
    Subscribe.to_profile(public_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:profile, public_key}, socket) do
    Subscribe.to_profile(public_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:update_profile, %Profile{} = profile}, %{private_key: private_key} = socket) do
    Client.update_profile(profile, private_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:note, note_id}, socket) do
    Client.subscribe_note(note_id)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:notes}, %{public_key: public_key} = socket) do
    Client.subscribe_notes(public_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:notes, pubkey}, socket) do
    Client.subscribe_notes(pubkey)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:delete, event_ids, note}, %{private_key: private_key} = socket) do
    Client.delete_events(event_ids, note, private_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:deletions, pubkeys}, socket) do
    Client.subscribe_deletions(pubkeys)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:repost, note_id}, %{private_key: private_key} = socket) do
    Client.repost(note_id, private_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:reposts}, %{public_key: public_key} = socket) do
    Client.subscribe_reposts([public_key])

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:reposts, pubkeys}, socket) do
    Client.subscribe_reposts(pubkeys)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:reactions}, %{public_key: public_key} = socket) do
    Client.subscribe_reactions([public_key])

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:reactions, pubkeys}, socket) do
    Client.subscribe_reactions(pubkeys)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:timeline}, %{public_key: public_key} = socket) do
    Client.subscribe_timeline(public_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:timeline, pubkey}, socket) do
    Client.subscribe_timeline(pubkey)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:connection, _relay_url, :error, _message} = message, socket) do
    # credo:disable-for-next-line
    IO.inspect(message)

    {:noreply, socket}
  end

  @impl true
  def handle_info({relay, %MetadataEvent{} = event}, socket) do
    Logger.info("From #{relay}, got a profile: #{inspect(event)}")

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
