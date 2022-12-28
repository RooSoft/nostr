defmodule NostrApp do
  use GenServer

  alias Nostr.Client

  def start_link(relay, <<_::256>> = private_key) do
    {:ok, public_key} = K256.Schnorr.verifying_key_from_signing_key(private_key)
    args = %{relay: relay, private_key: private_key, public_key: public_key}

    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(%{relay: relay} = args) do
    case Nostr.Client.start_link(relay) do
      {:ok, nostr_client_pid} ->
        {:ok, args |> Map.put(:nostr_client_pid, nostr_client_pid)}

      {:error, message} ->
        {:stop, message}
    end
  end

  def send(note) do
    GenServer.cast(__MODULE__, {:send, note})
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
  def handle_info(
        :connected,
        %{nostr_client_pid: nostr_client_pid, public_key: _public_key} = socket
      ) do
    public_key = <<0x51CCC482F89773349EF650407294A8B6A1658F0B377B3CAFB714423A29FC31C7::256>>

    _request_id =
      Nostr.Client.subscribe_author(
        nostr_client_pid,
        public_key,
        10
      )

    {:noreply, socket}
  end

  @impl true
  def handle_info({request_id, %Nostr.Event.TextEvent{event: event}}, socket) do
    # IO.puts("TEXT EVENT")
    # IO.inspect(event, label: "#{request_id}")
    # IO.inspect(Nostr.Validator.validate_event(event))

    {:noreply, socket}
  end

  @impl true
  def handle_info({request_id, %Nostr.Event.EncryptedDirectMessageEvent{event: event}}, socket) do
    IO.puts("ENCRYPTED DM EVENT")
    IO.inspect(event, label: "#{request_id}")
    IO.inspect(Nostr.Validator.validate_event(event))

    {:noreply, socket}
  end

  @impl true
  def handle_info({_request_id, _event}, socket) do
    # IO.inspect event, label: "#{request_id}"

    {:noreply, socket}
  end
end
