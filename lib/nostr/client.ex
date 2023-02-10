defmodule Nostr.Client do
  @moduledoc """
  Connects to a relay through websockets
  """

  use Supervisor

  require Logger

  alias NostrBasics.{Event}
  alias NostrBasics.Event.{Signer, Validator}
  alias NostrBasics.Keys.{PublicKey, PrivateKey}
  alias NostrBasics.Crypto.AES256CBC

  alias Nostr.Event.Types.{EncryptedDirectMessageEvent, TextEvent}
  alias Nostr.Models.{Profile, Note}
  alias Nostr.Client.Relays.RelayManager

  alias Nostr.Client.Subscriptions.{
    ProfileSubscription,
    RecommendedServersSubscription,
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

  alias Nostr.Client.Relays.RelaySocket

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
      RelayManager,
      {DynamicSupervisor, name: Nostr.Subscriptions, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def add_relay(relay_url) do
    RelayManager.add(relay_url)
  end

  @doc """
  Get an author's profile
  """
  @spec subscribe_profile(PublicKey.id()) ::
          {:ok, DynamicSupervisor.on_start_child()} | {:error, String.t()}
  def subscribe_profile(pubkey) do
    case PublicKey.to_binary(pubkey) do
      {:ok, binary_pubkey} ->
        {
          :ok,
          DynamicSupervisor.start_child(
            Nostr.Subscriptions,
            {ProfileSubscription, [RelayManager.active_pids(), binary_pubkey, self()]}
          )
        }

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Get an author's recommended servers
  """
  @spec subscribe_recommended_servers() ::
          {:ok, DynamicSupervisor.on_start_child()} | {:error, String.t()}
  def subscribe_recommended_servers() do
    {
      :ok,
      DynamicSupervisor.start_child(
        Nostr.Subscriptions,
        {RecommendedServersSubscription, [RelayManager.active_pids(), self()]}
      )
    }
  end

  @doc """
  Update the profile that's linked to the private key
  """
  @spec update_profile(Profile.t(), PrivateKey.id()) :: GenServer.on_start()
  def update_profile(%Profile{} = profile, privkey) do
    RelayManager.active_pids()
    |> UpdateProfile.start_link(profile, privkey)
  end

  @doc """
  Get an author's contacts
  """
  @spec subscribe_contacts(PublicKey.id()) :: DynamicSupervisor.on_start_child()
  def subscribe_contacts(pubkey) do
    case PublicKey.to_binary(pubkey) do
      {:ok, binary_pubkey} ->
        DynamicSupervisor.start_child(
          Nostr.Subscriptions,
          {ContactsSubscription, [RelayManager.active_pids(), binary_pubkey, self()]}
        )

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Follow a new contact using either a binary public key or a npub
  """
  @spec follow(PublicKey.id(), PrivateKey.id()) ::
          {:ok, GenServer.on_start()} | {:error, binary()}
  def follow(pubkey, privkey) do
    with {:ok, binary_privkey} <- PrivateKey.to_binary(privkey),
         {:ok, binary_pubkey} <- PublicKey.to_binary(pubkey) do
      {
        :ok,
        Follow.start_link(RelayManager.active_pids(), binary_pubkey, binary_privkey)
      }
    else
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  Unfollow from a contact
  """
  @spec unfollow(PublicKey.id(), PrivateKey.id()) ::
          {:ok, GenServer.on_start()} | {:error, binary()}
  def unfollow(pubkey, privkey) do
    with {:ok, binary_privkey} <- PrivateKey.to_binary(privkey),
         {:ok, binary_pubkey} <- PublicKey.to_binary(pubkey) do
      {
        :ok,
        Unfollow.start_link(RelayManager.active_pids(), binary_pubkey, binary_privkey)
      }
    else
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  Get encrypted direct messages from a private key
  """
  @spec encrypted_direct_messages(PrivateKey.id()) :: DynamicSupervisor.on_start_child()
  def encrypted_direct_messages(private_key) do
    case PrivateKey.to_binary(private_key) do
      {:ok, binary_private_key} ->
        DynamicSupervisor.start_child(
          Nostr.Subscriptions,
          {EncryptedDirectMessagesSubscription,
           [RelayManager.active_pids(), binary_private_key, self()]}
        )

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Sends an encrypted direct message
  """
  @spec send_encrypted_direct_messages(PublicKey.id(), String.t(), PrivateKey.id()) ::
          :ok | {:error, binary()}
  def send_encrypted_direct_messages(remote_pubkey, message, private_key) do
    with {:ok, binary_remote_pubkey} <- PublicKey.to_binary(remote_pubkey),
         {:ok, binary_private_key} <- PrivateKey.to_binary(private_key),
         {:ok, binary_local_pubkey} <- PublicKey.from_private_key(binary_private_key),
         encrypted_message = AES256CBC.encrypt(message, binary_private_key, binary_remote_pubkey),
         dm_event =
           EncryptedDirectMessageEvent.create(
             encrypted_message,
             binary_local_pubkey,
             binary_remote_pubkey
           ),
         {:ok, signed_event} <- Signer.sign_event(dm_event.event, private_key),
         :ok <- Validator.validate_event(signed_event) do
      for relay_pid <- RelayManager.active_pids() do
        RelaySocket.send_event(relay_pid, signed_event)
      end

      :ok
    else
      {:error, message} when is_atom(message) -> Atom.to_string(message)
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  Get a note by id
  """
  @spec subscribe_note(Note.id()) :: DynamicSupervisor.on_start_child()
  def subscribe_note(note_id) do
    case Event.Id.to_binary(note_id) do
      {:ok, binary_note_id} ->
        DynamicSupervisor.start_child(
          Nostr.Subscriptions,
          {NoteSubscription, [RelayManager.active_pids(), binary_note_id, self()]}
        )

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Get an author's notes
  """
  @spec subscribe_notes(list(Note.id())) ::
          {:ok, DynamicSupervisor.on_start_child()} | {:error, String.t()}
  def subscribe_notes(pubkeys) when is_list(pubkeys) do
    case PublicKey.to_binary(pubkeys) do
      {:ok, binary_pub_keys} ->
        {
          :ok,
          DynamicSupervisor.start_child(
            Nostr.Subscriptions,
            {NotesSubscription, [RelayManager.active_pids(), binary_pub_keys, self()]}
          )
        }

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Deletes events
  """
  @spec delete_events(list(Note.id()), String.t(), PrivateKey.id()) ::
          {:ok, GenServer.on_start()} | {:error, String.t()}
  def delete_events(note_ids, note, privkey) do
    with {:ok, binary_privkey} <- PrivateKey.to_binary(privkey),
         {:ok, binary_note_ids} <- Event.Id.to_binary(note_ids) do
      {:ok,
       DeleteEvents.start_link(RelayManager.active_pids(), binary_note_ids, note, binary_privkey)}
    else
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  Get an author's deletions
  """
  @spec subscribe_deletions(list()) :: DynamicSupervisor.on_start_child()
  def subscribe_deletions(pubkeys) do
    case PublicKey.to_binary(pubkeys) do
      {:ok, binary_pubkeys} ->
        DynamicSupervisor.start_child(
          Nostr.Subscriptions,
          {DeletionsSubscription, [RelayManager.active_pids(), binary_pubkeys, self()]}
        )

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Reposts a note
  """
  @spec repost(Note.id(), PrivateKey.id()) :: {:ok, GenServer.on_start()} | {:error, String.t()}
  def repost(note_id, privkey) do
    with {:ok, binary_privkey} <- PrivateKey.to_binary(privkey),
         {:ok, "note", binary_note_id} <- Event.Id.to_binary(note_id) do
      {:ok, SendRepost.start_link(RelayManager.active_pids(), binary_note_id, binary_privkey)}
    else
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  Get an author's reposts
  """
  @spec subscribe_reposts(list()) :: DynamicSupervisor.on_start_child()
  def subscribe_reposts(pubkeys) do
    case PublicKey.to_binary(pubkeys) do
      {:ok, binary_pubkeys} ->
        DynamicSupervisor.start_child(
          Nostr.Subscriptions,
          {RepostsSubscription, [RelayManager.active_pids(), binary_pubkeys, self()]}
        )

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Get an author's reactions
  """
  @spec subscribe_reactions(list(PublicKey.id())) ::
          {:ok, DynamicSupervisor.on_start_child()} | {:error, String.t()}
  def subscribe_reactions(pubkeys) do
    case PublicKey.to_binary(pubkeys) do
      {:ok, binary_pubkeys} ->
        {
          :ok,
          DynamicSupervisor.start_child(
            Nostr.Subscriptions,
            {ReactionsSubscription, [RelayManager.active_pids(), binary_pubkeys, self()]}
          )
        }

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Get an author's realtime timeline including notes from everyone the author follows
  """
  @spec subscribe_timeline(PublicKey.id()) :: DynamicSupervisor.on_start_child()
  def subscribe_timeline(pubkey) do
    case PublicKey.to_binary(pubkey) do
      {:ok, binary_pubkey} ->
        DynamicSupervisor.start_child(
          Nostr.Subscriptions,
          {TimelineSubscription, [RelayManager.active_pids(), binary_pubkey, self()]}
        )

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Sends a note to the relay
  """
  @spec send_note(String.t(), PrivateKey.id()) :: :ok | {:error, String.t()}
  def send_note(note, privkey) do
    with {:ok, binary_privkey} <- PrivateKey.to_binary(privkey),
         {:ok, pubkey} <- PublicKey.from_private_key(privkey),
         text_event = TextEvent.create(note, pubkey),
         {:ok, signed_event} <- Signer.sign_event(text_event.event, binary_privkey),
         :ok <- Validator.validate_event(signed_event) do
      for relay_pid <- RelayManager.active_pids() do
        RelaySocket.send_event(relay_pid, signed_event)
      end

      :ok
    else
      {:error, message} when is_atom(message) -> {:error, Atom.to_string(message)}
      {:error, message} -> {:error, message}
    end
  end

  @spec react(Note.id(), PrivateKey.id(), String.t()) ::
          {:ok, GenServer.on_start()} | {:error, String.t()}
  def react(note_id, privkey, content \\ "+") do
    with {:ok, binary_privkey} <- PrivateKey.to_binary(privkey),
         {:ok, "note", binary_note_id} <- Event.Id.to_binary(note_id) do
      {
        :ok,
        SendReaction.start_link(
          RelayManager.active_pids(),
          binary_note_id,
          binary_privkey,
          content
        )
      }
    else
      {:error, message} -> {:error, message}
    end
  end

  def subscriptions() do
    DynamicSupervisor.which_children(Nostr.Subscriptions)
    |> Enum.map(fn {:undefined, pid, :worker, [type]} ->
      {pid, type}
    end)
  end

  def unsubscribe(pid) do
    DynamicSupervisor.terminate_child(Nostr.Subscriptions, pid)
    #    GenServer.call(pid, {:terminate, :shutdown})
  end
end
