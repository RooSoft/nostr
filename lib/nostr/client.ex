defmodule Nostr.Client do
  require Logger

  alias Nostr.Event
  alias Nostr.Event.{Request, TextEvent}
  alias K256.Schnorr

  @default_relay "wss://relay.nostr.pro"
  @default_config {}

  def start_link(relay_url \\ @default_relay, config \\ @default_config) do
    WebSockex.start_link(
      relay_url,
      Nostr.Client.Server,
      %{client_pid: self(), config: config}
    )
  end

  def subscribe_author(pid, pubkey, max_messages \\ 100) do
    {request_id, request} = Request.author(pubkey, max_messages)

    WebSockex.cast(pid, {:send_message, request})

    request_id
  end

  def send_note(_pid, note, privkey) do
    IO.puts("WILL SEND A NOTE")

    {:ok, pubkey} = Schnorr.verifying_key_from_signing_key(privkey)

    pubkey |> IO.inspect(label: "public key", base: :hex)

    # note_event =
    TextEvent.create(pubkey, note)
    |> Event.add_id()
    |> IO.inspect(label: "event with id")

    # {:ok, sig} = Schnorr.create_signature(note_event, privkey) |> IO.inspect(label: "signature")

    #  IO.inspect(sig, label: "signature")
  end
end
