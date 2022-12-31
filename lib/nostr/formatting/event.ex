defimpl Inspect, for: Nostr.Event do
  alias Nostr.Formatting.HexBinary

  def inspect(%Nostr.Event{} = event, opts) do
    %{
      event
      | pubkey: %HexBinary{data: event.pubkey},
        sig: %HexBinary{data: event.sig}
    }
    |> Inspect.Any.inspect(opts)
  end
end
