defmodule NostrApp.Server do
  use GenServer

  require Logger

  alias Nostr.Client
  alias Nostr.Event.Types.MetadataEvent

  @default_relay "wss://relay.nostr.pro"

  @impl true
  def init(%{relay: relay, private_key: private_key} = args) do
    with {:ok, public_key} <- K256.Schnorr.verifying_key_from_signing_key(private_key),
         {:ok, supervisor_pid} <- Nostr.Client.start_link() do
      relay =
        case relay do
          nil -> @default_relay
          relay -> relay
        end

      Client.add_relay(relay)

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
  def handle_cast({:send, note}, %{private_key: private_key} = socket) do
    Client.send_note(note, private_key)

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
  def handle_cast({:timeline, pubkey}, socket) do
    Client.subscribe_timeline(pubkey)

    {:noreply, socket}
  end

  @impl true
  def handle_info(%MetadataEvent{} = event, socket) do
    Logger.info("Got a profile: #{inspect(event)}")

    {:noreply, socket}
  end

  @impl true
  def handle_info(event, socket) do
    IO.inspect(event)

    {:noreply, socket}
  end

  # @impl true
  # def handle_info({request_id, %TextEvent{event: event}}, socket) do
  #   IO.puts("TEXT EVENT")
  #   IO.inspect(event, label: "#{request_id}")
  #   IO.inspect(Nostr.Event.Validator.validate_event(event))

  #   #  IO.puts("is there a timeline?")
  #   #  IO.inspect(Registry.lookup(Registry.Subscriptions, "timeline"))

  #   {:noreply, socket}
  # end

  # @impl true
  # def handle_info({request_id, %EncryptedDirectMessageEvent{event: event}}, socket) do
  #   IO.puts("ENCRYPTED DM EVENT")
  #   IO.inspect(event, label: "#{request_id}")
  #   IO.inspect(Nostr.Event.Validator.validate_event(event))

  #   {:noreply, socket}
  # end

  # @impl true
  # def handle_info({request_id, event}, socket) do
  #   IO.inspect(event, label: "#{request_id}")

  #   {:noreply, socket}
  # end

  # @impl true
  # def handle_info({:timeline, :note, note}, socket) do
  #   IO.puts("Got a note")
  #   IO.inspect(note)

  #   {:noreply, socket}
  # end
end
