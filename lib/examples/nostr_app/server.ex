defmodule NostrApp.Server do
  use GenServer

  alias Nostr.Client
  alias Nostr.Event.Types.{EncryptedDirectMessageEvent, TextEvent}


  @impl true
  def init(%{relay: relay, private_key: private_key} = args) do
    with {:ok, public_key} <- K256.Schnorr.verifying_key_from_signing_key(private_key),
         {:ok, nostr_client_pid} <- Nostr.Client.start_link(relay) do
      {
        :ok,
        args
        |> Map.put(:nostr_client_pid, nostr_client_pid)
        |> Map.put(:public_key, public_key)
      }
    else
      {:error, message} ->
        {:stop, message}
    end
  end

  @impl true
  def handle_cast(
        {:send, note},
        %{nostr_client_pid: nostr_client_pid, private_key: private_key} = socket
      ) do
    Client.send_note(nostr_client_pid, note, private_key)

    {:noreply, socket}
  end

  @impl true
  def handle_cast(
        {:contacts, pubkey},
        %{nostr_client_pid: nostr_client_pid} = socket
      ) do
    Client.get_contacts(nostr_client_pid, pubkey)

    {:noreply, socket}
  end

  @impl true
  def handle_cast(
        {:profile, pubkey},
        %{nostr_client_pid: nostr_client_pid} = socket
      ) do
    Client.get_profile(nostr_client_pid, pubkey)

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        :connected,
        %{nostr_client_pid: nostr_client_pid, public_key: public_key} = socket
      ) do
    _request_id =
      Client.subscribe_author(
        nostr_client_pid,
        public_key,
        10
      )

    {:noreply, socket}
  end

  @impl true
  def handle_info({request_id, %TextEvent{event: event}}, socket) do
    IO.puts("TEXT EVENT")
    IO.inspect(event, label: "#{request_id}")
    IO.inspect(Nostr.Event.Validator.validate_event(event))

    {:noreply, socket}
  end

  @impl true
  def handle_info({request_id, %EncryptedDirectMessageEvent{event: event}}, socket) do
    IO.puts("ENCRYPTED DM EVENT")
    IO.inspect(event, label: "#{request_id}")
    IO.inspect(Nostr.Event.Validator.validate_event(event))

    {:noreply, socket}
  end

  @impl true
  def handle_info({request_id, event}, socket) do
    IO.inspect(event, label: "#{request_id}")

    {:noreply, socket}
  end
end
