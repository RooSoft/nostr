defimpl Inspect, for: Nostr.Models.Contact do
  alias Nostr.Formatting.HexBinary

  def inspect(%Nostr.Models.Contact{} = contact, opts) do
    %{
      contact
      | pubkey: %HexBinary{data: contact.pubkey}
    }
    |> Inspect.Any.inspect(opts)
  end
end
