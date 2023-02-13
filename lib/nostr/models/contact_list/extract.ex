defmodule Nostr.Models.ContactList.Extract do
  @contact_kind 3

  alias Nostr.Models.{Contact, ContactList}

  @doc """
  Converts an %Event{} into a %ContactList{}

  ## Examples
      iex> %NostrBasics.Event{
      ...>   id: "811574fe1f5b49e301b8a554d71f7a63314efc540b1778e2ad813a564b12739b",
      ...>   pubkey: <<0x5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2::256>>,
      ...>   created_at: ~U[2023-02-11 13:15:17Z],
      ...>   kind: 3,
      ...>   tags: [["p", "5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2", ""]],
      ...>   content: ~s({"wss://nos.lol":{"write":false,"read":true}}),
      ...>   sig: <<0xc177a56607ef5f5d137478aeca851791a35514f5ad55f8e0e3901f561c004cc1d15a1b048a03c6f4b01e5c675ecd132fb0b5a2cc3cc7562e848fe5a968c658c5::512>>
      ...> }
      ...> |> Nostr.Models.ContactList.Extract.from_event
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
          relays: [%{url: "wss://nos.lol", read?: true, write?: false}]
        }
      }
  """
  @spec from_event(Event.t()) :: {:ok, ContactList.t()} | {:error, String.t()}
  def from_event(event) do
    relays = extract_relays(event.content)
    contacts = Enum.map(event.tags, &parse_contact/1)

    case event.kind do
      @contact_kind ->
        {:ok, create_contact_list(event.pubkey, contacts, relays)}

      kind ->
        {
          :error,
          "Tried to parse a contacts event with kind #{kind} instead of #{@contact_kind}"
        }
    end
  end

  defp extract_relays(nil), do: []
  defp extract_relays(""), do: []

  defp extract_relays(relays_list) when is_binary(relays_list) do
    relays_list
    |> Jason.decode!()
    |> extract_relays()
  end

  defp extract_relays(relays_list) when is_map(relays_list) do
    relays_list
    |> Map.keys()
    |> Enum.map(fn url ->
      item = relays_list[url]

      %{
        url: url,
        read?: Map.get(item, "read"),
        write?: Map.get(item, "write")
      }
    end)
  end

  defp parse_contact(["p" | [hex_pubkey | []]]) do
    pubkey = Binary.from_hex(hex_pubkey)

    %Contact{pubkey: pubkey}
  end

  defp parse_contact(["p" | [hex_pubkey | [main_relay | []]]]) do
    pubkey = Binary.from_hex(hex_pubkey)

    %Contact{pubkey: pubkey, main_relay: main_relay}
  end

  defp parse_contact(["p" | [hex_pubkey | [main_relay | [petname]]]]) do
    pubkey = Binary.from_hex(hex_pubkey)

    %Contact{pubkey: pubkey, main_relay: main_relay, petname: petname}
  end

  defp parse_contact(data), do: %{unknown_content_type: data}

  defp create_contact_list(pubkey, contacts, relays) do
    %ContactList{
      pubkey: pubkey,
      contacts: contacts,
      relays: relays
    }
  end
end
