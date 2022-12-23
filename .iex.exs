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
    _request_id = Nostr.Client.subscribe_author(
      server_pid,
      "efc83f01c8fb309df2c8866b8c7924cc8b6f0580afdde1d6e16e2b6107c2862c"
    )

    _request_id = Nostr.Client.subscribe_author(
      server_pid,
      "d75a0bcc4b494628d51ceab95ca1b34b9b23b1cb3a715beb1c5a8d963d161460"
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({request_id, event}, socket) do
    IO.inspect event, label: "#{request_id}"

    {:noreply, socket}
  end
end

Receiver.start_link()
