defmodule Receiver do
  use GenServer

  @relay "wss://relay.nostr.pro"

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, server_pid} = Nostr.Client.start_link(@relay)

    {:ok, %{server_pid: server_pid}}
  end

  @impl true
  def handle_info(:connected, %{server_pid: server_pid} = socket) do
    Nostr.Client.subscribe_author(server_pid, "efc83f01c8fb309df2c8866b8c7924cc8b6f0580afdde1d6e16e2b6107c2862c")

    {:noreply, socket}
  end

  @impl true
  def handle_info(message, socket) do
    IO.inspect message, label: "From Receiver"

    {:noreply, socket}
  end
end

Receiver.start_link()
