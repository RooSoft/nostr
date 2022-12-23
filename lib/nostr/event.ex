defmodule Nostr.Event do
  require Logger

  alias Nostr.Event.{
    MetadataEvent,
    TextEvent,
    ContactsEvent,
    EncryptedDirectMessageEvent,
    BoostEvent,
    ReactionEvent,
    EndOfRecordedHistoryEvent
  }

  def dispatch(["EVENT", request_id, %{"kind" => 0} = content]) do
    {request_id, MetadataEvent.parse(content)}
  end

  def dispatch(["EVENT", request_id, %{"kind" => 1} = content]) do
    {request_id, TextEvent.parse(content)}
  end

  def dispatch(["EVENT", request_id, %{"kind" => 2} = content]) do
    {request_id, Logger.info("2- recommend relay: #{inspect(content)}")}
  end

  def dispatch(["EVENT", request_id, %{"kind" => 3} = content]) do
    {request_id, ContactsEvent.parse(content)}
  end

  def dispatch(["EVENT", request_id, %{"kind" => 4} = content]) do
    {request_id, EncryptedDirectMessageEvent.parse(content)}
  end

  def dispatch(["EVENT", request_id, %{"kind" => 5} = content]) do
    {request_id, Logger.info("5- event deletion: #{inspect(content)}")}
  end

  def dispatch(["EVENT", request_id, %{"kind" => 6} = content]) do
    {request_id, BoostEvent.parse(content)}
  end

  def dispatch(["EVENT", request_id, %{"kind" => 7} = content]) do
    {request_id, ReactionEvent.parse(content)}
  end

  def dispatch(["EVENT", _request_id, %{"kind" => 40} = content]) do
    Logger.info("40- channel creation: #{inspect(content)}")
  end

  def dispatch(["EVENT", _request_id, %{"kind" => 41} = content]) do
    Logger.info("41- channel metadata: #{inspect(content)}")
  end

  def dispatch(["EVENT", _request_id, %{"kind" => 42} = content]) do
    Logger.info("42- channel message: #{inspect(content)}")
  end

  def dispatch(["EVENT", _request_id, %{"kind" => 43} = content]) do
    Logger.info("43- channel hide message: #{inspect(content)}")
  end

  def dispatch(["EVENT", _request_id, %{"kind" => 44} = content]) do
    Logger.info("44- channel mute user: #{inspect(content)}")
  end

  def dispatch(["EVENT", _request_id, %{"kind" => 45} = content]) do
    Logger.info("45- public chat reserved: #{inspect(content)}")
  end

  def dispatch(["EVENT", _request_id, %{"kind" => 46} = content]) do
    Logger.info("46- public chat reserved: #{inspect(content)}")
  end

  def dispatch(["EVENT", _request_id, %{"kind" => 47} = content]) do
    Logger.info("47- public chat reserved: #{inspect(content)}")
  end

  def dispatch(["EVENT", _request_id, %{"kind" => 48} = content]) do
    Logger.info("48- public chat reserved: #{inspect(content)}")
  end

  def dispatch(["EVENT", _request_id, %{"kind" => 49} = content]) do
    Logger.info("49- public chat reserved: #{inspect(content)}")
  end

  def dispatch(["EVENT", _request_id, %{"kind" => kind} = content]) do
    Logger.info("#{kind}- unknown event type: #{inspect(content)}")
  end

  def dispatch([type, request, content]) do
    Logger.warning("#{type} #{request} #{content}: unknown event type")
  end

  def dispatch(["EOSE", request_id]) do
    {request_id, %EndOfRecordedHistoryEvent{}}
  end

  def dispatch(contents) do
    Logger.warning("unknown event type: #{contents}")
  end
end
