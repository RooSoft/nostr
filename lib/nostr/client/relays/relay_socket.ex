defmodule Nostr.Client.Relays.RelaySocket do
  require Logger

  alias Nostr.Client.Relays.RelaySocket.Server

  defstruct [
    :url,
    :conn,
    :websocket,
    :request_ref,
    :owner_pid,
    :caller,
    :status,
    :resp_headers,
    :closing?,
    subscriptions: []
  ]

  @doc """
  Creates a socket to a relay

  ## Examples
    iex> Nostr.Client.Relays.RelaySocket.start_link("wss://relay.nostr.pro")
  """
  @spec start_link(list()) :: GenServer.on_start()
  def start_link([relay_url, owner_pid]) do
    GenServer.start_link(Server, %{relay_url: relay_url, owner_pid: owner_pid})
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def subscriptions(pid) do
    GenServer.call(pid, {:subscriptions})
  end

  @doc """
  Revokes a subscription from a relay
  """
  @spec unsubscribe(pid(), atom()) :: :ok
  def unsubscribe(pid, subscription_id) do
    GenServer.cast(pid, {:unsubscribe, subscription_id})
  end

  def send_event(pid, event) do
    GenServer.cast(pid, {:send_event, event})
  end

  def subscribe_profile(pid, pubkey) do
    GenServer.call(pid, {:profile, pubkey, self()})
  end

  @spec subscribe_contacts(pid(), <<_::256>>) :: atom()
  def subscribe_contacts(pid, pubkey, limit \\ 10) do
    GenServer.call(pid, {:contacts, pubkey, limit, self()})
  end

  @spec subscribe_note(pid(), <<_::256>>) :: atom()
  def subscribe_note(pid, note_id) do
    GenServer.call(pid, {:note, note_id, self()})
  end

  @spec subscribe_notes(pid(), list(<<_::256>>), integer()) :: atom()
  def subscribe_notes(pid, pubkeys, limit \\ 10) when is_list(pubkeys) do
    GenServer.call(pid, {:notes, pubkeys, limit, self()})
  end

  @spec subscribe_deletions(pid(), list(<<_::256>>), integer()) :: atom()
  def subscribe_deletions(pid, pubkeys, limit \\ 10) when is_list(pubkeys) do
    GenServer.call(pid, {:deletions, pubkeys, limit, self()})
  end

  @spec subscribe_reposts(pid(), list(<<_::256>>), integer()) :: atom()
  def subscribe_reposts(pid, pubkeys, limit \\ 10) when is_list(pubkeys) do
    GenServer.call(pid, {:reposts, pubkeys, limit, self()})
  end

  @spec subscribe_reactions(pid(), list(<<_::256>>), integer()) :: atom()
  def subscribe_reactions(pid, pubkeys, limit \\ 10) when is_list(pubkeys) do
    GenServer.call(pid, {:reactions, pubkeys, limit, self()})
  end

  @spec subscribe_encrypted_direct_messages(pid(), <<_::256>>, integer()) ::
          atom()
  def subscribe_encrypted_direct_messages(pid, pubkey, limit \\ 10) do
    GenServer.call(pid, {:encrypted_direct_messages, pubkey, limit, self()})
  end
end
