defmodule Nostr.Client.Workflows.Follow do
  @moduledoc """
  A process that's responsible to subscribe and listen to relays so
  it can properly enable a user's to follow a new contact
  """

  #### TODO: make sure to have the latest contact list before upgrading it
  ####       right now, we update the first contact list that we receive
  ####       and it might not be the latest...
  ####       maybe will have to make sure we connect to the relay list from
  ####       the user's metadata, get all contact lists, and pick the latest

  use GenServer

  alias NostrBasics.Event.{Signer, Validator}
  alias NostrBasics.Keys.PublicKey

  alias Nostr.Client.Relays.RelaySocket
  alias Nostr.Event.Types.{ContactsEvent}
  alias Nostr.Models.ContactList
  alias Nostr.Client.Relays.RelaySocket.Publisher

  def start_link(relay_pids, follow_pubkey, privkey) do
    GenServer.start(__MODULE__, %{
      relay_pids: relay_pids,
      privkey: privkey,
      follow_pubkey: follow_pubkey,
      owner_pid: self()
    })
  end

  @impl true
  def init(%{relay_pids: relay_pids, privkey: privkey} = state) do
    case PublicKey.from_private_key(privkey) do
      {:ok, pubkey} ->
        subscriptions = subscribe_contacts(relay_pids, pubkey)

        {
          :ok,
          state
          |> Map.put(:subscriptions, subscriptions)
          |> Map.put(:got_contact_list, false)
        }

      {:error, message} ->
        {:stop, {:shutdown, message}}
    end
  end

  def handle_info(:unsubscribe_contacts, %{subscriptions: subscriptions} = state) do
    unsubscribe_contacts(subscriptions)

    {
      :noreply,
      state
      |> Map.put(:subscriptions, [])
    }
  end

  def handle_info(
        {:follow, %ContactList{} = contact_list},
        %{privkey: privkey, relay_pids: relay_pids, follow_pubkey: follow_pubkey} = state
      ) do
    follow(follow_pubkey, privkey, contact_list, relay_pids)

    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:end_of_stored_events, _relay, _subscription_id},
        %{got_contact_list: true} = state
      ) do
    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:end_of_stored_events, _relay, _subscription_id},
        %{privkey: privkey, got_contact_list: false} = state
      ) do
    profile_pubkey = PublicKey.from_private_key!(privkey)

    new_contact_list = %ContactList{
      pubkey: profile_pubkey,
      contacts: []
    }

    send(self(), {:follow, new_contact_list})

    {
      :noreply,
      state
      |> Map.put(:got_contact_list, true)
    }
  end

  @impl true
  # when we first get the contacts, time to add a new pubkey on it
  def handle_info(
        {relay, _subscription_id, contacts_event},
        %{got_contact_list: false, owner_pid: owner_pid} = state
      ) do
    case ContactList.from_event(contacts_event) do
      {:ok, contact_list} ->
        send(self(), {:follow, contact_list})
        send(self(), :unsubscribe_contacts)

        {
          :noreply,
          state
          |> Map.put(:got_contact_list, true)
        }

      {:error, message} ->
        Publisher.workflow_error(owner_pid, relay, message)

        {:stop, message, state}
    end
  end

  defp subscribe_contacts(relay_pids, pubkey) do
    relay_pids
    |> Enum.map(fn relay_pid ->
      subscription_id = RelaySocket.subscribe_contacts(relay_pid, pubkey)

      {relay_pid, subscription_id}
    end)
  end

  defp unsubscribe_contacts(subscriptions) do
    for {relaysocket_pid, subscription_id} <- subscriptions do
      RelaySocket.unsubscribe(relaysocket_pid, subscription_id)
    end
  end

  defp follow(follow_pubkey, privkey, %ContactList{} = contact_list, relay_pids) do
    contact_list = ContactList.add(contact_list, follow_pubkey)

    {:ok, signed_event} =
      contact_list
      |> ContactsEvent.create_event()
      |> Signer.sign_event(privkey)

    :ok = Validator.validate_event(signed_event)

    for relay_pid <- relay_pids do
      RelaySocket.send_event(relay_pid, signed_event)
    end
  end
end
