defmodule Nostr.Event.Types.ContactsEvent do
  @moduledoc """
  Contacts event management, including event creation and parsing
  """

  require Logger

  alias Nostr.Event
  alias Nostr.Models.{Contact, ContactList}

  @kind 3
  @empty_content ""
  @empty_petname ""

  def create_event(%ContactList{
        pubkey: pubkey,
        contacts: contacts
      }) do
    tags =
      contacts
      |> Enum.map(fn %Contact{pubkey: pubkey} ->
        ["p", Binary.to_hex(pubkey), @empty_petname]
      end)

    %{
      Event.create(@empty_content, pubkey)
      | kind: @kind,
        tags: tags,
        created_at: DateTime.utc_now()
    }
    |> Event.add_id()
  end

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
