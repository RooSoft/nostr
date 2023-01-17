defmodule Nostr.Client do
  @moduledoc """
  Connects to a relay through websockets
  """

  use Supervisor

  require Logger

  alias Nostr.Event.{Signer, Validator}
  alias Nostr.Event.Types.{TextEvent}
  alias Nostr.Models.{Profile}

  alias Nostr.Client.Subscriptions.{
    ProfileSubscription,
    ContactsSubscription,
    NoteSubscription,
    NotesSubscription,
    DeletionsSubscription,
    RepostsSubscription,
    ReactionsSubscription,
    TimelineSubscription,
    EncryptedDirectMessagesSubscription
  }

  alias Nostr.Client.Workflows.{
    Follow,
    Unfollow,
    DeleteEvents,
    SendReaction,
    SendRepost,
    UpdateProfile
  }

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
    DynamicSupervisor.start_child(Nostr.RelaySockets, {Nostr.RelaySocket, [relay_url, self()]})
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
  Update the profile that's linked to the private key
  """
  @spec follow(<<_::256>>, <<_::256>>) :: :ok
  def update_profile(%Profile{} = profile, privkey) do
    relay_pids()
    |> UpdateProfile.start_link(profile, privkey)
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
  Follow a new contact
  """
  @spec follow(<<_::256>>, <<_::256>>) :: :ok
  def follow(pubkey, privkey) do
    relay_pids()
    |> Follow.start_link(pubkey, privkey)
  end

  @doc """
  Unfollow from a contact
  """
  @spec unfollow(<<_::256>>, <<_::256>>) :: :ok
  def unfollow(pubkey, privkey) do
    relay_pids()
    |> Unfollow.start_link(pubkey, privkey)
  end

  @doc """
  Unfollow from a contact
  """
  @spec encrypted_direct_messages(<<_::256>>) :: :ok
  def encrypted_direct_messages(pubkey) do
    DynamicSupervisor.start_child(
      Nostr.Subscriptions,
      {EncryptedDirectMessagesSubscription, [relay_pids(), pubkey, self()]}
    )
  end

  @doc """
  Get a note by id
  """
  @spec subscribe_note(<<_::256>>) :: binary()
  def subscribe_note(note_id) do
    DynamicSupervisor.start_child(
      Nostr.Subscriptions,
      {NoteSubscription, [relay_pids(), note_id, self()]}
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
  Deletes events
  """
  def delete_events(note_id, note, privkey) do
    relay_pids()
    |> DeleteEvents.start_link(note_id, note, privkey)
  end

  @doc """
  Get an author's deletions
  """
  @spec subscribe_deletions(list()) :: binary()
  def subscribe_deletions(pubkeys) do
    DynamicSupervisor.start_child(
      Nostr.Subscriptions,
      {DeletionsSubscription, [relay_pids(), pubkeys, self()]}
    )
  end

  @doc """
  Reposts a note
  """
  def repost(note_id, privkey) do
    relay_pids()
    |> SendRepost.start_link(note_id, privkey)
  end

  @doc """
  Get an author's reposts
  """
  @spec subscribe_reposts(list()) :: binary()
  def subscribe_reposts(pubkeys) do
    DynamicSupervisor.start_child(
      Nostr.Subscriptions,
      {RepostsSubscription, [relay_pids(), pubkeys, self()]}
    )
  end

  @doc """
  Get an author's reactions
  """
  @spec subscribe_reactions(list()) :: binary()
  def subscribe_reactions(pubkeys) do
    DynamicSupervisor.start_child(
      Nostr.Subscriptions,
      {ReactionsSubscription, [relay_pids(), pubkeys, self()]}
    )
  end

  @doc """
  Get an author's realtime timeline including notes from everyone the author follows
  """
  @spec subscribe_timeline(<<_::256>>) :: binary()
  def subscribe_timeline(pubkey) do
    DynamicSupervisor.start_child(
      Nostr.Subscriptions,
      {TimelineSubscription, [relay_pids(), pubkey, self()]}
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

  def react(note_id, privkey, content \\ "+") do
    relay_pids()
    |> SendReaction.start_link(note_id, privkey, content)
  end
end
