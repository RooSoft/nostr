defmodule Nostr.Event.Contacts do
  require Logger

  def parse(content) do
    %{
      "content" => content,
      "created_at" => 1_671_685_107,
      "id" => _id,
      "kind" => 3,
      "pubkey" => _pubkey,
      "sig" => _sig,
      "tags" => tags
    } = content

    contacts =
      tags
      |> Enum.map(&parse_contact/1)

    content |> IO.inspect(label: "------------------CONTACTS CONTENT", limit: :infinity)
    contacts |> IO.inspect(label: "------------------CONTACTS TAGS", limit: :infinity)
  end

  def parse_contact(["p" | [pubkey | []]]), do: %{pubkey: pubkey}

  def parse_contact(["p" | [pubkey | [main_relay | []]]]),
    do: %{pubkey: pubkey, main_relay: main_relay}

  def parse_contact(["p" | [pubkey | [main_relay | [petname]]]]),
    do: %{pubkey: pubkey, main_relay: main_relay, petname: petname}

  def parse_contact(data), do: %{unknown_content_type: data}
end
