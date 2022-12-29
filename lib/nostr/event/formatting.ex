defimpl Inspect, for: Nostr.Event do
  alias Nostr.Formatting

  def inspect(%Nostr.Event{} = event, opts) do
    %{
      event
      | pubkey: Formatting.to_hex(event.pubkey),
        sig: Formatting.to_hex(event.sig)
    }
    |> Inspect.Any.inspect(opts)
  end
end
