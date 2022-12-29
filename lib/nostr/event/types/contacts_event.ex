defmodule Nostr.Event.Types.ContactsEvent do
  require Logger

  defstruct event: %Nostr.Event{}, contacts: []

  alias Nostr.Event
  alias Nostr.Event.Types.ContactsEvent
  alias Nostr.Models.Client

  @kind 3

  def parse(content) do
    %{
      # according to NIP-02, should be ignored
      "content" => _content,
      "created_at" => unix_created_at,
      "id" => id,
      "kind" => @kind,
      "pubkey" => hex_pubkey,
      "sig" => hex_sig,
      "tags" => tags
    } = content

    pubkey = Binary.from_hex(hex_pubkey)
    sig = Binary.from_hex(hex_sig)

    contacts = Enum.map(tags, &parse_contact/1)

    with {:ok, created_at} <- DateTime.from_unix(unix_created_at) do
      %ContactsEvent{
        event: %Event{
          id: id,
          pubkey: pubkey,
          sig: sig,
          created_at: created_at,
          kind: @kind
        },
        contacts: contacts
      }
    else
      {:error, _message} ->
        %ContactsEvent{
          event: %Event{
            id: id,
            pubkey: pubkey,
            sig: sig,
            kind: @kind
          },
          contacts: contacts
        }
    end
  end

  def parse_contact(["p" | [pubkey | []]]), do: %Client{pubkey: pubkey}

  def parse_contact(["p" | [pubkey | [main_relay | []]]]),
    do: %Client{pubkey: pubkey, main_relay: main_relay}

  def parse_contact(["p" | [pubkey | [main_relay | [petname]]]]),
    do: %Client{pubkey: pubkey, main_relay: main_relay, petname: petname}

  def parse_contact(data), do: %{unknown_content_type: data}
end
