defmodule Nostr.Client.FrameDispatcher do
  @moduledoc """
  Raw websocket frames are sent to this module so they end up being
  dispatched to the right module depending on their types
  """

  require Logger

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
    Logger.debug("NOTICE: #{message}")

    {:ok, {"", "NOTICE #{message}"}}
  end

  def dispatch(["OK", request_id, ok?, message]) do
    Logger.debug("OK: #{message}")

    {:ok, {request_id, "OK #{request_id}, #{ok?}, #{message}"}}
  end

  def dispatch([type | _remaining]) do
    Logger.debug("UNKNOWN FRAME TYPE: #{type}")

    {:error, "unknown frame type: #{type}"}
  end
end
