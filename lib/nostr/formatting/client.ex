defimpl Inspect, for: Nostr.Models.Client do
  alias Nostr.Formatting.HexBinary

  def inspect(%Nostr.Models.Client{} = client, opts) do
    %{
      client
      | pubkey: %HexBinary{data: client.pubkey}
    }
    |> Inspect.Any.inspect(opts)
  end
end
