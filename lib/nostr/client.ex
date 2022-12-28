defmodule Nostr.Client do
  @moduledoc """
  Connects to a relay through websockets
  """

  require Logger

  alias Nostr.Event.{TextEvent}
  alias Nostr.Client.{SubscribeRequest, SendRequest}
  alias Nostr.Signer
  alias K256.Schnorr

  @default_relay "wss://relay.nostr.pro"
  @default_config {}

  @doc """
  Starts the client

  ## Examples
    iex> Nostr.Client.start_link("wss://relay.nostr.pro")
  """
  @spec start_link(String.t(), tuple()) :: {:ok, pid()} | {:error, binary()}
  def start_link(relay_url \\ @default_relay, config \\ @default_config) do
    WebSockex.start_link(
      relay_url,
      Nostr.Client.Server,
      %{client_pid: self(), config: config}
    )
  end

  @doc """
  Subscribes to an author's events
  """
  @spec subscribe_author(pid(), <<_::256>>, Integer.t()) :: binary()
  def subscribe_author(pid, pubkey, max_messages \\ 100) do
    {request_id, request} = SubscribeRequest.author(pubkey, max_messages)

    WebSockex.cast(pid, {:send_message, request})

    request_id
  end

  @doc """
  Sends a note to the relay
  """
  @spec send_note(pid(), String.t(), <<_::256>>) :: :ok
  def send_note(pid, note, privkey) do
    {:ok, pubkey} = Schnorr.verifying_key_from_signing_key(privkey)

    text_event = TextEvent.create(pubkey, note)

    {:ok, signed_event} =
      text_event.event
      |> Signer.sign_event(privkey)

    request = SendRequest.event(signed_event)

    WebSockex.cast(pid, {:send_message, request})
  end
end
