defmodule Nostr.Models.ContactList.Convert do
  alias NostrBasics.Event
  alias Nostr.Models.{Contact, ContactList}

  @contact_kind 3
  @empty_petname ""

  def to_event(%ContactList{pubkey: pubkey, contacts: contacts, relays: relays}) do
    content = content_from_relays(relays)
    tags = tags_from_contacts(contacts)

    %{
      Event.create(@contact_kind, content, pubkey)
      | tags: tags,
        created_at: DateTime.utc_now()
    }
  end

  defp tags_from_contacts(contacts) do
    contacts
    |> Enum.map(fn %Contact{pubkey: pubkey} ->
      ["p", Binary.to_hex(pubkey), @empty_petname]
    end)
  end

  defp content_from_relays(nil), do: ""

  defp content_from_relays(relays) do
    for %{url: url, read?: read?, write?: write?} <- relays do
      {url, %{read: read?, write: write?}}
    end
    |> Map.new()
    |> Jason.encode!()
  end
end
