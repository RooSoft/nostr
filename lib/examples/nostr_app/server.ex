defmodule NostrApp.Server do
  use GenServer

  require Logger

  alias Nostr.Client
  alias Nostr.Event.Types.MetadataEvent

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
  def handle_cast({:contacts, pubkey}, socket) do
    Client.subscribe_contacts(pubkey)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:profile, pubkey}, socket) do
    Client.subscribe_profile(pubkey)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:notes, pubkey}, socket) do
    Client.subscribe_notes(pubkey)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:deletions, pubkeys}, socket) do
    Client.subscribe_deletions(pubkeys)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:reposts, pubkeys}, socket) do
    Client.subscribe_reposts(pubkeys)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:reactions, pubkeys}, socket) do
    Client.subscribe_reactions(pubkeys)

    {:noreply, socket}
  end

  @impl true
  def handle_cast({:timeline, pubkey}, socket) do
    Client.subscribe_timeline(pubkey)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:connection, _relay_url, :error, _message} = message, socket) do
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
    IO.puts("from #{relay}")
    IO.inspect(event)

    {:noreply, socket}
  end

  @impl true
  def handle_info(event, socket) do
    IO.inspect(event)

    {:noreply, socket}
  end

  defp connect_to_relays(relays) do
    for relay <- relays do
      Client.add_relay(relay)
    end
  end
end
