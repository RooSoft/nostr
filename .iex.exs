defmodule Receiver do
  use GenServer

  @relay "wss://relay.nostr.pro"

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(stack) do
    Nostr.Client.start_link(@relay)
    
    {:ok, stack}
  end

  @impl true
  def handle_info(message, socket) do
    IO.inspect message, label: "From Receiver"

    {:noreply, socket}
  end
end

Receiver.start_link()
