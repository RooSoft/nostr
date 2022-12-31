defmodule Nostr.Event.Types.ContactsEvent do
  require Logger

  defstruct event: %Nostr.Event{}, contacts: []

  alias Nostr.Event
  alias Nostr.Event.Types.ContactsEvent
  alias Nostr.Models.Client

  @kind 3

  def parse(body) do
    event = Event.parse(body)

    IO.inspect(event.tags)
    contacts = Enum.map(event.tags, &parse_contact/1)

    case event.kind do
      @kind ->
        {
          :ok,
          %ContactsEvent{
            event: event,
            contacts: contacts
          }
        }

      kind ->
        {
          :error,
          "Tried to parse a contacts event with kind #{kind} instead of #{@kind}"
        }
    end
  end

  def parse_contact(["p" | [hex_pubkey | []]]) do
    pubkey = Binary.from_hex(hex_pubkey)

    %Client{pubkey: pubkey}
  end

  def parse_contact(["p" | [hex_pubkey | [main_relay | []]]]) do
    pubkey = Binary.from_hex(hex_pubkey)

    %Client{pubkey: pubkey, main_relay: main_relay}
  end

  def parse_contact(["p" | [hex_pubkey | [main_relay | [petname]]]]) do
    pubkey = Binary.from_hex(hex_pubkey)

    %Client{pubkey: pubkey, main_relay: main_relay, petname: petname}
  end

  def parse_contact(data), do: %{unknown_content_type: data}
end
