defmodule Nostr.Models.ContactList do
  defstruct [:id, :pubkey, :created_at, :contacts]

  alias Nostr.Models.{Contact, ContactList}

  def add(%ContactList{contacts: contacts} = contact_list, pubkey) do
    contact = %Contact{pubkey: pubkey}

    new_contacts = [contact | contacts]

    %{contact_list | contacts: new_contacts}
  end
end
