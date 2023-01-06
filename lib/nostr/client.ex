defmodule Nostr.Client do
  @moduledoc """
  Connects to a relay through websockets
  """

  use Supervisor

  require Logger

  alias Nostr.Event.{Signer, Validator}
  alias Nostr.Event.Types.{TextEvent}
  alias Nostr.Client.Subscriptions.{ProfileSubscription, ContactsSubscription, NotesSubscription}
  alias Nostr.RelaySocket
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
  @spec subscribe_contacts(<<_::256>>) :: binary()
  def subscribe_contacts(pubkey) do
    DynamicSupervisor.start_child(
      Nostr.Subscriptions,
      {ContactsSubscription, [relay_pids(), pubkey, self()]}
    )
  end

  @doc """
  Get an author's notes
  """
  @spec subscribe_notes(<<_::256>>) :: binary()
  def subscribe_notes(pubkey) do
    DynamicSupervisor.start_child(
      Nostr.Subscriptions,
      {NotesSubscription, [relay_pids(), pubkey, self()]}
    )
  end

  @doc """
  Sends a note to the relay
  """
  @spec send_note(String.t(), K256.Schnorr.signing_key()) ::
          :ok | {:error, binary() | atom()}
  def send_note(note, privkey) do
    with {:ok, pubkey} <- Schnorr.verifying_key_from_signing_key(privkey),
         text_event = TextEvent.create(note, pubkey),
         {:ok, signed_event} <- Signer.sign_event(text_event.event, privkey),
         :ok <- Validator.validate_event(signed_event) do
      for relay_pid <- relay_pids(), do: RelaySocket.send_event(relay_pid, signed_event)
    else
      {:error, message} -> {:error, message}
    end
  end
end
