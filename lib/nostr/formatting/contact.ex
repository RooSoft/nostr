defimpl Inspect, for: NostrBasics.Models.Contact do
  alias NostrBasics.HexBinary

  def inspect(%NostrBasics.Models.Contact{} = contact, opts) do
    %{
      contact
      | pubkey: %HexBinary{data: contact.pubkey}
    }
    |> Inspect.Any.inspect(opts)
  end
end
