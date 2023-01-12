defmodule Nostr.Models.ContactList do
  defstruct [:id, :pubkey, :created_at, :contacts]

  alias Nostr.Models.ContactList

  def add(%ContactList{contacts: contacts} = contact_list, pubkey) do
    new_contacts = [pubkey | contacts]

    %{contact_list | contacts: new_contacts}
  end
end
