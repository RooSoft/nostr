defmodule Nostr.Client do
  require Logger

  @default_relay "wss://relay.nostr.pro"

  def start_link(relay_url \\ @default_relay) do
    {:ok, pid} = WebSockex.start_link(relay_url, Nostr.Client.Server, %{client_pid: self()})

    Logger.warning("#{inspect(pid)}")

    {:ok, pid}
  end
end
