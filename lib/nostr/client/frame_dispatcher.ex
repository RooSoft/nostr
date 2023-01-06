defmodule Nostr.Client.FrameDispatcher do
  alias Nostr.Event
  alias Nostr.Event.Types.EndOfStoredEvents

  def dispatch(["EVENT" | [request_id | [data]]]) do
    case Event.Dispatcher.dispatch(data) do
      {:ok, event} -> {:ok, {request_id, event}}
      {:error, message} -> {:error, message}
    end
  end

  def dispatch(["EOSE", request_id]) do
    {:ok, {request_id, %EndOfStoredEvents{}}}
  end

  def dispatch(["NOTICE", message]) do
    {:ok, {"", "NOTICE #{message}"}}
  end

  def dispatch(["OK", request_id, ok?, message]) do
    {:ok, {request_id, "OK #{request_id}, #{ok?}, #{message}"}}
  end

  def dispatch([type | _remaining]) do
    {:error, "unknown frame type: #{type}"}
  end
end
