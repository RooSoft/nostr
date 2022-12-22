defmodule Nostr.Event.ContactsEvent do
  require Logger

  defstruct [:id, :pubkey, :sig, :created_at, contacts: []]

  alias Nostr.Event.ContactsEvent
  alias Nostr.Models.Client

  def parse(content) do
    %{
      # according to NIP-02, should be ignored
      "content" => _content,
      "created_at" => unix_created_at,
      "id" => id,
      "kind" => 3,
      "pubkey" => pubkey,
      "sig" => sig,
      "tags" => tags
    } = content

    contacts = Enum.map(tags, &parse_contact/1)

    with {:ok, created_at} <- DateTime.from_unix(unix_created_at) do
      %ContactsEvent{
        id: id,
        contacts: contacts,
        pubkey: pubkey,
        sig: sig,
        created_at: created_at
      }
    else
      {:error, _message} ->
        %ContactsEvent{
          id: id,
          contacts: contacts,
          pubkey: pubkey,
          sig: sig
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
