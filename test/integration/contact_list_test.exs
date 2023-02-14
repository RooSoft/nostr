defmodule Nostr.Test.Integration.ContactListTest do
  use ExUnit.Case, async: true

  alias NostrBasics.Models.ContactList

  test "encode and decode a contact list" do
    contact_list = %NostrBasics.Models.ContactList{
      pubkey: <<0x5AB9F2EFB1FDA6BC32696F6F3FD715E156346175B93B6382099D23627693C3F2::256>>,
      contacts: [
        %NostrBasics.Models.Contact{
          pubkey: <<0x5AB9F2EFB1FDA6BC32696F6F3FD715E156346175B93B6382099D23627693C3F2::256>>,
          main_relay: "",
          petname: nil
        }
      ],
      relays: [%{url: "wss://nos.lol", read?: true, write?: false}]
    }

    {:ok, new_contact_list} =
      contact_list
      |> ContactList.to_event()
      |> ContactList.from_event()

    assert new_contact_list == contact_list
  end
end
