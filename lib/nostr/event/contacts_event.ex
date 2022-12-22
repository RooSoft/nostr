defmodule Nostr.Event.ContactsEvent do
  require Logger

  defstruct [:created_at, contacts: []]

  alias Nostr.Event.ContactsEvent

  def parse(content) do
    %{
      # according to NIP-02, should be ignored
      "content" => _content,
      "created_at" => unix_created_at,
      "id" => _id,
      "kind" => 3,
      "pubkey" => _pubkey,
      "sig" => _sig,
      "tags" => tags
    } = content

    contacts = Enum.map(tags, &parse_contact/1)

    with {:ok, created_at} <- DateTime.from_unix(unix_created_at) do
      %ContactsEvent{
        contacts: contacts,
        created_at: created_at
      }
    else
      {:error, _message} ->
        %ContactsEvent{
          contacts: contacts
        }
    end
  end

  def parse_contact(["p" | [pubkey | []]]), do: %{pubkey: pubkey}

  def parse_contact(["p" | [pubkey | [main_relay | []]]]),
    do: %{pubkey: pubkey, main_relay: main_relay}

  def parse_contact(["p" | [pubkey | [main_relay | [petname]]]]),
    do: %{pubkey: pubkey, main_relay: main_relay, petname: petname}

  def parse_contact(data), do: %{unknown_content_type: data}
end
