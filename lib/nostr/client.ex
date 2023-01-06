defmodule Nostr.Client do
  @moduledoc """
  Connects to a relay through websockets
  """

  use Supervisor

  require Logger

  alias Nostr.Event.{Signer, Validator}
  alias Nostr.Event.Types.{TextEvent}
  alias Nostr.Client.{SendRequest}
  alias Nostr.Client.Requests.{SubscribeRequest, Contacts}
  alias Nostr.Client.Subscriptions.{ProfileSubscription, ContactsSubscription}
  alias K256.Schnorr

  @default_config {}

  @doc """
  Starts the client

  ## Examples
    iex> Nostr.Client.start_link("wss://relay.nostr.pro")
  """
  @spec start_link(tuple()) :: Supervisor.on_start()
  def start_link(config \\ @default_config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init(_config) do
    children = [
      {DynamicSupervisor, name: Nostr.RelaySockets, strategy: :one_for_one},
      {DynamicSupervisor, name: Nostr.Subscriptions, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def add_relay(relay_url) do
    DynamicSupervisor.start_child(Nostr.RelaySockets, {Nostr.RelaySocket, relay_url})
  end

  def relay_pids do
    DynamicSupervisor.which_children(Nostr.RelaySockets)
    |> Enum.map(&elem(&1, 1))
  end

  @doc """
  Subscribes to an author's events
  """
  @spec subscribe_author(pid(), <<_::256>>, integer()) :: binary()
  def subscribe_author(pid, pubkey, max_messages \\ 100) do
    {request_id, request} = SubscribeRequest.author(pubkey, max_messages)

    WebSockex.cast(pid, {:send_message, request})

    request_id
  end

  @doc """
  Get an author's contacts
  """
  @spec get_contacts(pid(), <<_::256>>) :: binary()
  def get_contacts(pid, pubkey) do
    {request_id, request} = Contacts.get(pubkey)

    WebSockex.cast(pid, {:send_message, request})

    request_id
  end

  @doc """
  Get an author's profile
  """
  @spec subscribe_profile(<<_::256>>) :: binary()
  def subscribe_profile(pubkey) do
    DynamicSupervisor.start_child(
      Nostr.Subscriptions,
      {ProfileSubscription, [relay_pids(), pubkey, self()]}
    )
  end

  @doc """
  Get an author's contacts
  """
  @spec subscribe_profile(<<_::256>>) :: binary()
  def subscribe_contacts(pubkey) do
    DynamicSupervisor.start_child(
      Nostr.Subscriptions,
      {ContactsSubscription, [relay_pids(), pubkey, self()]}
    )
  end

  @doc """
  Sends a note to the relay
  """
  @spec send_note(pid(), String.t(), K256.Schnorr.signing_key()) ::
          :ok | {:error, binary() | atom()}
  def send_note(pid, note, privkey) do
    with {:ok, pubkey} <- Schnorr.verifying_key_from_signing_key(privkey),
         text_event = TextEvent.create(note, pubkey),
         {:ok, signed_event} <- Signer.sign_event(text_event.event, privkey),
         :ok <- Validator.validate_event(signed_event) do
      request = SendRequest.event(signed_event)

      WebSockex.cast(pid, {:send_message, request})
    else
      {:error, message} -> {:error, message}
    end
  end
end
