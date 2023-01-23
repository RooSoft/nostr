defmodule Nostr.Client do
  @moduledoc """
  Connects to a relay through websockets
  """

  use Supervisor

  require Logger

  alias Nostr.Keys.{PublicKey, PrivateKey}
  alias Nostr.Event.{Signer, Validator}
  alias Nostr.Event.Types.{EncryptedDirectMessageEvent, TextEvent}
  alias Nostr.Models.{Profile, Note}

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

  alias Nostr.Crypto.AES256CBC
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
  @spec subscribe_profile(Schnorr.verifying_key() | binary()) ::
          {:ok, DynamicSupervisor.on_start_child()} | {:error, String.t()}
  def subscribe_profile(pubkey) do
    case PublicKey.to_binary(pubkey) do
      {:ok, binary_pubkey} ->
        DynamicSupervisor.start_child(
          Nostr.Subscriptions,
          {ProfileSubscription, [relay_pids(), binary_pubkey, self()]}
        )

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Update the profile that's linked to the private key
  """
  @spec update_profile(Profile.t(), <<_::256>>) :: GenServer.on_start()
  def update_profile(%Profile{} = profile, privkey) do
    relay_pids()
    |> UpdateProfile.start_link(profile, privkey)
  end

  @doc """
  Get an author's contacts
  """
  @spec subscribe_contacts(<<_::256>>) :: DynamicSupervisor.on_start_child()
  def subscribe_contacts(pubkey) do
    case PublicKey.to_binary(pubkey) do
      {:ok, binary_pubkey} ->
        DynamicSupervisor.start_child(
          Nostr.Subscriptions,
          {ContactsSubscription, [relay_pids(), binary_pubkey, self()]}
        )

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Follow a new contact using either a binary public key or a npub
  """
  @spec follow(<<_::256>> | String.t(), <<_::256>> | String.t()) ::
          {:ok, GenServer.on_start()} | {:error, binary()}
  def follow(pubkey, privkey) do
    with {:ok, binary_privkey} <- PrivateKey.to_binary(privkey),
         {:ok, binary_pubkey} <- PublicKey.to_binary(pubkey) do
      {
        :ok,
        Follow.start_link(relay_pids(), binary_pubkey, binary_privkey)
      }
    else
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  Unfollow from a contact
  """
  @spec unfollow(<<_::256>> | String.t(), <<_::256>> | String.t()) ::
          {:ok, GenServer.on_start()} | {:error, binary()}
  def unfollow(pubkey, privkey) do
    with {:ok, binary_privkey} <- PrivateKey.to_binary(privkey),
         {:ok, binary_pubkey} <- PublicKey.to_binary(pubkey) do
      {
        :ok,
        Unfollow.start_link(relay_pids(), binary_pubkey, binary_privkey)
      }
    else
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  Get encrypted direct messages from a private key
  """
  @spec encrypted_direct_messages(<<_::256>>) :: DynamicSupervisor.on_start_child()
  def encrypted_direct_messages(private_key) do
    case PrivateKey.to_binary(private_key) do
      {:ok, binary_private_key} ->
        DynamicSupervisor.start_child(
          Nostr.Subscriptions,
          {EncryptedDirectMessagesSubscription, [relay_pids(), binary_private_key, self()]}
        )

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Sends an encrypted direct message
  """
  @spec send_encrypted_direct_messages(<<_::256>>, String.t(), <<_::256>>) ::
          {:ok, :ok} | {:error, binary() | atom()}
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
      for relay_pid <- relay_pids() do
        RelaySocket.send_event(relay_pid, signed_event)
      end

      :ok
    else
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  Get a note by id
  """
  @spec subscribe_note(<<_::256>>) :: DynamicSupervisor.on_start_child()
  def subscribe_note(note_id) do
    case Note.Id.to_binary(note_id) do
      {:ok, binary_note_id} ->
        DynamicSupervisor.start_child(
          Nostr.Subscriptions,
          {NoteSubscription, [relay_pids(), binary_note_id, self()]}
        )

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Get an author's notes
  """
  @spec subscribe_notes(list(<<_::256>>)) :: DynamicSupervisor.on_start_child()
  def subscribe_notes(pubkeys) when is_list(pubkeys) do
    case PublicKey.to_binary(pubkeys) do
      {:ok, binary_pub_keys} ->
        {
          :ok,
          DynamicSupervisor.start_child(
            Nostr.Subscriptions,
            {NotesSubscription, [relay_pids(), binary_pub_keys, self()]}
          )
        }

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Deletes events
  """
  def delete_events(note_ids, note, privkey) do
    with {:ok, binary_privkey} <- PrivateKey.to_binary(privkey),
         {:ok, binary_note_ids} <- Note.Id.to_binary(note_ids) do
      DeleteEvents.start_link(relay_pids(), binary_note_ids, note, binary_privkey)
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
          {DeletionsSubscription, [relay_pids(), binary_pubkeys, self()]}
        )

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Reposts a note
  """
  @spec repost(<<_::256>> | String.t(), <<_::256>> | String.t()) :: GenServer.on_start()
  def repost(note_id, privkey) do
    with {:ok, binary_privkey} <- PrivateKey.to_binary(privkey),
         {:ok, binary_note_id} <- Note.Id.to_binary(note_id) do
      SendRepost.start_link(relay_pids(), binary_note_id, binary_privkey)
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
          {RepostsSubscription, [relay_pids(), binary_pubkeys, self()]}
        )

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Get an author's reactions
  """
  @spec subscribe_reactions(list(<<_::256>>)) :: DynamicSupervisor.on_start_child()
  def subscribe_reactions(pubkeys) do
    case PublicKey.to_binary(pubkeys) do
      {:ok, binary_pubkeys} ->
        DynamicSupervisor.start_child(
          Nostr.Subscriptions,
          {ReactionsSubscription, [relay_pids(), binary_pubkeys, self()]}
        )

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Get an author's realtime timeline including notes from everyone the author follows
  """
  @spec subscribe_timeline(<<_::256>>) :: DynamicSupervisor.on_start_child()
  def subscribe_timeline(pubkey) do
    case PublicKey.to_binary(pubkey) do
      {:ok, binary_pubkey} ->
        DynamicSupervisor.start_child(
          Nostr.Subscriptions,
          {TimelineSubscription, [relay_pids(), binary_pubkey, self()]}
        )

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Sends a note to the relay
  """
  @spec send_note(String.t(), <<_::256>>) :: :ok | {:error, binary() | atom()}
  def send_note(note, privkey) do
    IO.puts("start of send_note")

    with {:ok, binary_privkey} <- PrivateKey.to_binary(privkey),
         {:ok, pubkey} <- PublicKey.from_private_key(privkey),
         text_event = TextEvent.create(note, pubkey),
         {:ok, signed_event} <- Signer.sign_event(text_event.event, binary_privkey),
         :ok <- Validator.validate_event(signed_event) do
      for relay_pid <- relay_pids() do
        RelaySocket.send_event(relay_pid, signed_event)
      end
    else
      {:error, message} -> {:error, message} |> IO.inspect()
    end
  end

  @spec react(Note.id(), PrivateKey.id(), String.t()) ::
          {:ok, GenServer.on_start()} | {:error, String.t()}
  def react(note_id, privkey, content \\ "+") do
    with {:ok, binary_privkey} <- PrivateKey.to_binary(privkey),
         {:ok, binary_note_id} <- Note.Id.to_binary(note_id) do
      {
        :ok,
        SendReaction.start_link(relay_pids(), binary_note_id, binary_privkey, content)
      }
    else
      {:error, message} -> {:error, message}
    end
  end
end
