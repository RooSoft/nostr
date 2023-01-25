defmodule Nostr.Client.Workflows.Follow do
  @moduledoc """
  A process that's responsible to subscribe and listen to relays so
  it can properly enable a user's to follow a new contact
  """

  use GenServer

  alias Nostr.RelaySocket
  alias Nostr.Event.{Signer, Validator}
  alias Nostr.Event.Types.{ContactsEvent, EndOfStoredEvents}
  alias Nostr.Models.ContactList
  alias Nostr.Keys.PublicKey

  def start_link(relay_pids, follow_pubkey, privkey) do
    GenServer.start(__MODULE__, %{
      relay_pids: relay_pids,
      privkey: privkey,
      follow_pubkey: follow_pubkey
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
          |> Map.put(:treated, false)
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
        {:follow, contacts},
        %{privkey: privkey, relay_pids: relay_pids, follow_pubkey: follow_pubkey} = state
      ) do
    follow(follow_pubkey, privkey, contacts, relay_pids)

    {:noreply, state}
  end

  @impl true
  def handle_info({_relay, %EndOfStoredEvents{}}, %{privkey: privkey, treated: false} = state) do
    profile_pubkey = Nostr.Keys.PublicKey.from_private_key!(privkey)

    new_contact_list = %Nostr.Models.ContactList{
      pubkey: profile_pubkey,
      created_at: DateTime.utc_now(),
      contacts: []
    }

    send(self(), {:follow, new_contact_list})

    {
      :noreply,
      state
      |> Map.put(:treated, true)
    }
  end

  @impl true
  # when we first get the contacts, time to add a new pubkey on it
  def handle_info({_relay, contacts}, %{treated: false} = state) do
    send(self(), {:follow, contacts})
    send(self(), :unsubscribe_contacts)

    {
      :noreply,
      state
      |> Map.put(:treated, true)
    }
  end

  @impl true
  # when the follow has already been executed
  def handle_info({_relay, _contacts}, %{treated: true} = state) do
    {:noreply, state}
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

  defp follow(follow_pubkey, privkey, contact_list, relay_pids) do
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
