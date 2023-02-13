defmodule Nostr.Models.ContactList do
  @moduledoc """
  Represents a nostr user's contact list
  """

  defstruct [:pubkey, :contacts, :relays]

  alias Nostr.Models.{Contact, ContactList}

  @type t :: %ContactList{}

  @doc """
  Converts an %Event{} into a %ContactList{}

  ## Examples
      iex> %NostrBasics.Event{
      ...>   id: "811574fe1f5b49e301b8a554d71f7a63314efc540b1778e2ad813a564b12739b",
      ...>   pubkey: <<0x5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2::256>>,
      ...>   created_at: ~U[2023-02-11 13:15:17Z],
      ...>   kind: 3,
      ...>   tags: [["p", "5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2", ""]],
      ...>   content: "",
      ...>   sig: <<0xc177a56607ef5f5d137478aeca851791a35514f5ad55f8e0e3901f561c004cc1d15a1b048a03c6f4b01e5c675ecd132fb0b5a2cc3cc7562e848fe5a968c658c5::512>>
      ...> }
      ...> |> Nostr.Models.ContactList.from_event
      {
        :ok,
        %Nostr.Models.ContactList{
          pubkey: <<0x5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2::256>>,
          contacts: [
            %Nostr.Models.Contact{
              pubkey: <<0x5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2::256>>,
              main_relay: "",
              petname: nil
            }
          ],
          relays: []
        }
      }
  """
  @spec from_event(Event.t()) :: ContactList.t()
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
