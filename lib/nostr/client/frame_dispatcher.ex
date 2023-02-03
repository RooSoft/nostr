defmodule Nostr.Client.FrameDispatcher do
  @moduledoc """
  Raw websocket frames are sent to this module so they end up being
  dispatched to the right module depending on their types
  """

  require Logger

  alias Nostr.Event
  alias Nostr.Event.Types.EndOfStoredEvents
  alias Nostr.Frames.{Ok, Notice}

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
    {:ok, {nil, %Notice{message: message}}}
  end

  def dispatch(["OK", request_id, persisted?, reason]) do
    {:ok, {request_id, %Ok{persisted?: persisted?, reason: reason}}}
  end

  def dispatch([type | _remaining]) do
    Logger.debug("UNKNOWN FRAME TYPE: #{type}")

    {:error, "unknown frame type: #{type}"}
  end

  def dispatch(unknown) do
    Logger.debug("UNKNOWN FRAME: #{inspect(unknown)}")

    {:error, "unknown frame: #{unknown}"}
  end
end
