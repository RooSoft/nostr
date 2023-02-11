defmodule Nostr.Models.ContactList do
  @moduledoc """
  Represents a nostr user's contact list
  """

  defstruct [:pubkey, :contacts, :relays]

  alias Nostr.Models.{Contact, ContactList}

  @type t :: %ContactList{}

  def from_event(event) do
    ContactList.Converter.from_event(event)
  end

  def add(%ContactList{contacts: contacts} = contact_list, pubkey) do
    contact = %Contact{pubkey: pubkey}

    new_contacts = [contact | contacts]

    %{contact_list | contacts: new_contacts}
  end

  def remove(%ContactList{contacts: contacts} = contact_list, pubkey_to_remove) do
    new_contacts =
      contacts
      |> Enum.filter(fn %Contact{pubkey: contact_pubkey} ->
        pubkey_to_remove != contact_pubkey
      end)

    %{contact_list | contacts: new_contacts}
  end
end
