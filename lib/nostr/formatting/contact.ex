defimpl Inspect, for: Nostr.Models.Contact do
  alias NostrBasics.HexBinary

  def inspect(%Nostr.Models.Contact{} = contact, opts) do
    %{
      contact
      | pubkey: %HexBinary{data: contact.pubkey}
    }
    |> Inspect.Any.inspect(opts)
  end
end
