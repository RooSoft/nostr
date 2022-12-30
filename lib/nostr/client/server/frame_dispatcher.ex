defmodule Nostr.Client.Server.FrameDispatcher do
  alias Nostr.Event

  def dispatch(data) do
    {:ok, Event.Dispatcher.dispatch(data)}
  end
end
