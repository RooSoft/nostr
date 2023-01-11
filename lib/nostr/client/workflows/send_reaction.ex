defmodule Nostr.Client.Workflows.SendReaction do
  use GenServer

  require Logger

  alias Nostr.RelaySocket
  alias Nostr.Event.Types.EndOfStoredEvents

  def start_link(relay_pids, note_id, privkey, content \\ "+") do
    GenServer.start(__MODULE__, %{
      relay_pids: relay_pids,
      note_id: note_id,
      privkey: privkey,
      content: content
    })
  end

  @impl true
  def init(%{relay_pids: relay_pids, note_id: note_id} = state) do
    subscriptions = subscribe_note(relay_pids, note_id)

    {
      :ok,
      state
      |> Map.put(:subscriptions, subscriptions)
      |> Map.put(:treated, false)
    }
  end

  def handle_info(:unsubscribe, %{subscriptions: subscriptions} = state) do
    unsubscribe(subscriptions)

    {
      :noreply,
      state
      |> Map.put(:subscriptions, [])
    }
  end

  def handle_info({:react, note}, %{privkey: privkey, content: content} = state) do
    react(note, privkey, content)

    {:noreply, state}
  end

  @impl true
  def handle_info({relay, %EndOfStoredEvents{}}, state) do
    ## nothing to do
    Logger.info("#{relay}: done")

    {:noreply, state}
  end

  @impl true
  # when we first get the note, time to react on it
  def handle_info({relay, note}, %{treated: false} = state) do
    Logger.info("found #{note.event.id} note on #{relay}")

    send(self(), {:react, note})
    send(self(), :unsubscribe)

    {
      :noreply,
      state
      |> Map.put(:treated, true)
    }
  end

  @impl true
  # when the note has already been reacted on
  def handle_info({relay, note}, %{treated: true} = state) do
    Logger.info("passing #{relay} #{note.event.id}...")

    {:noreply, state}
  end

  defp subscribe_note(relay_pids, note_id) do
    relay_pids
    |> Enum.map(fn relay_pid ->
      subscription_id = RelaySocket.subscribe_note(relay_pid, note_id)

      {relay_pid, subscription_id}
    end)
  end

  defp unsubscribe(subscriptions) do
    Logger.info("unsubscribing...")

    IO.inspect(subscriptions)

    for {relaysocket_pid, subscription_id} <- subscriptions do
      RelaySocket.unsubscribe(relaysocket_pid, subscription_id)
    end
  end

  defp react(note, _privkey, content) do
    Logger.info("reacting to #{note.event.id} with #{content}")
  end
end
