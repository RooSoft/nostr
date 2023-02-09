defimpl Inspect, for: Nostr.Models.ContactList do
  alias NostrBasics.HexBinary

  def inspect(%Nostr.Models.ContactList{} = contact_list, opts) do
    %{
      contact_list
      | pubkey: %HexBinary{data: contact_list.pubkey}
    }
    |> Inspect.Any.inspect(opts)
  end
end
