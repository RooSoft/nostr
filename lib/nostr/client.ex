defmodule Nostr.Client do
  require Logger

  alias Nostr.Event.{Request}

  @default_relay "wss://relay.nostr.pro"
  @default_config {}

  def start_link(relay_url \\ @default_relay, config \\ @default_config) do
    WebSockex.start_link(
      relay_url,
      Nostr.Client.Server,
      %{client_pid: self(), config: config}
    )
  end

  def subscribe_author(pid, pubkey, max_messages \\ 100) do
    request = Request.author(pubkey, max_messages)

    WebSockex.cast(pid, {:send_message, request})
  end
end
