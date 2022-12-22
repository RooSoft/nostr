defmodule Nostr.Event.MetadataEvent do
  require Logger

  defstruct [:content]

  alias Nostr.Event.MetadataEvent

  def parse(content) do
    %MetadataEvent{content: content}
  end
end
