defmodule Nostr.Event do
  require Logger

  alias Nostr.Event.{MetadataEvent, ContactsEvent, Reaction}

  def dispatch(["EVENT", "myreq", %{"kind" => 0} = content]) do
    MetadataEvent.parse(content)
  end

  def dispatch(["EVENT", "myreq", %{"kind" => 1} = content]) do
    Logger.info("1- text: #{inspect(content)}")
  end

  def dispatch(["EVENT", "myreq", %{"kind" => 2} = content]) do
    Logger.info("2- recommend relay: #{inspect(content)}")
  end

  def dispatch(["EVENT", "myreq", %{"kind" => 3} = content]) do
    ContactsEvent.parse(content)
  end

  def dispatch(["EVENT", "myreq", %{"kind" => 4} = content]) do
    Logger.info("4- encrypted direct messages: #{inspect(content)}")
  end

  def dispatch(["EVENT", "myreq", %{"kind" => 5} = content]) do
    Logger.info("5- event deletion: #{inspect(content)}")
  end

  def dispatch(["EVENT", "myreq", %{"kind" => 7} = content]) do
    Reaction.parse(content)
  end

  def dispatch(["EVENT", "myreq", %{"kind" => 40} = content]) do
    Logger.info("40- channel creation: #{inspect(content)}")
  end

  def dispatch(["EVENT", "myreq", %{"kind" => 41} = content]) do
    Logger.info("41- channel metadata: #{inspect(content)}")
  end

  def dispatch(["EVENT", "myreq", %{"kind" => 42} = content]) do
    Logger.info("42- channel message: #{inspect(content)}")
  end

  def dispatch(["EVENT", "myreq", %{"kind" => 43} = content]) do
    Logger.info("43- channel hide message: #{inspect(content)}")
  end

  def dispatch(["EVENT", "myreq", %{"kind" => 44} = content]) do
    Logger.info("44- channel mute user: #{inspect(content)}")
  end

  def dispatch(["EVENT", "myreq", %{"kind" => 45} = content]) do
    Logger.info("45- public chat reserved: #{inspect(content)}")
  end

  def dispatch(["EVENT", "myreq", %{"kind" => 46} = content]) do
    Logger.info("46- public chat reserved: #{inspect(content)}")
  end

  def dispatch(["EVENT", "myreq", %{"kind" => 47} = content]) do
    Logger.info("47- public chat reserved: #{inspect(content)}")
  end

  def dispatch(["EVENT", "myreq", %{"kind" => 48} = content]) do
    Logger.info("48- public chat reserved: #{inspect(content)}")
  end

  def dispatch(["EVENT", "myreq", %{"kind" => 49} = content]) do
    Logger.info("49- public chat reserved: #{inspect(content)}")
  end

  def dispatch(["EVENT", "myreq", %{"kind" => kind} = content]) do
    Logger.info("#{kind}- unknown event type: #{inspect(content)}")
  end

  def dispatch([type, request, content]) do
    Logger.warning("#{type} #{request} #{content}: unknown event type")
  end

  def dispatch(["EOSE", "myreq"]) do
    Logger.info("end of recorded history, what follow is live stuff")
  end

  def dispatch(contents) do
    Logger.warning("even more unknown event type")
    IO.inspect(contents)
  end
end
