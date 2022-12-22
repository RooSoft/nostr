defmodule Nostr.Event.Metadata do
  require Logger

  def parse(content) do
    content |> IO.inspect(label: "------------------METADATA", limit: :infinity)
  end
end
