defmodule Nostr.Client.Subscriptions.ProfileSubscription do
  use GenServer

  alias Nostr.RelaySocket
  alias Nostr.Event.Types.{MetadataEvent, EndOfStoredEvents}

  def start_link([relay_pids, pubkey, subscriber]) do
    GenServer.start_link(__MODULE__, %{
      relay_pids: relay_pids,
      pubkey: pubkey,
      subscriber: subscriber
    })
  end

  @impl true
  def init(%{relay_pids: relay_pids, pubkey: pubkey} = state) do
    relay_pids
    |> Enum.map(fn relay_pid ->
      RelaySocket.subscribe_profile(relay_pid, pubkey)
    end)

    {
      :ok,
      state
      |> Map.put(:found, false)
    }
  end

  @impl true
  def handle_info(
        {_relay_url, %Nostr.Event.Types.EndOfStoredEvents{}},
        %{found: false, pubkey: pubkey, subscriber: subscriber} = state
      ) do
    empty_event = MetadataEvent.create_event(pubkey)

    send(subscriber, empty_event)

    {:noreply, state}
  end

  @impl true
  def handle_info({_relay_url, %EndOfStoredEvents{}}, %{found: true} = state) do
    ## nothing to do, we're done here

    {:noreply, state}
  end

  @impl true
  def handle_info(
        {_relay_url, %MetadataEvent{} = event},
        %{subscriber: subscriber} = state
      ) do
    send(subscriber, event)

    {
      :noreply,
      %{state | found: true}
    }
  end
end
