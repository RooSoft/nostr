defmodule Nostr.Event.Types.ContactsEvent do
  require Logger

  #defstruct event: %Nostr.Event{}, contacts: []

  alias Nostr.Event
  #alias Nostr.Event.Types.ContactsEvent
  alias Nostr.Models.{Contact, ContactList}

  @kind 3

  def parse(body) do
    event = Event.parse(body)

    contacts = Enum.map(event.tags, &parse_contact/1)

    case event.kind do
      @kind ->
        {:ok, create_contact_list(event, contacts)}

      kind ->
        {
          :error,
          "Tried to parse a contacts event with kind #{kind} instead of #{@kind}"
        }
    end
  end

  defp parse_contact(["p" | [hex_pubkey | []]]) do
    pubkey = Binary.from_hex(hex_pubkey)

    %Contact{pubkey: pubkey}
  end

  defp parse_contact(["p" | [hex_pubkey | [main_relay | []]]]) do
    pubkey = Binary.from_hex(hex_pubkey)

    %Contact{pubkey: pubkey, main_relay: main_relay}
  end

  defp parse_contact(["p" | [hex_pubkey | [main_relay | [petname]]]]) do
    pubkey = Binary.from_hex(hex_pubkey)

    %Contact{pubkey: pubkey, main_relay: main_relay, petname: petname}
  end

  defp parse_contact(data), do: %{unknown_content_type: data}

  defp create_contact_list(event, contacts) do
    %ContactList{
      id: event.id,
      pubkey: event.pubkey,
      created_at: event.created_at,
      contacts: contacts
    }
  end
end
