defmodule Nostr.RelaySocket.FrameHandlerTest do
  use ExUnit.Case, async: true

  alias Nostr.RelaySocket.FrameHandler
  alias Nostr.Frames.{Ok}
  alias Nostr.Event.Types.{EndOfStoredEvents}

  test "manage an OK frame" do
    frame = ~s(["OK","a806462fec12d934e452e1375a2401ef",true,"duplicate:"])
    subscriptions = [a806462fec12d934e452e1375a2401ef: self()]
    relay_url = "my.relay.social"

    :ok = FrameHandler.handle_text_frame(frame, subscriptions, relay_url, self())

    assert_receive {^relay_url, %Ok{persisted?: true, reason: "duplicate:"}}
  end

  test "manage an EOSE frame" do
    frame = ~s(["EOSE","a806462fec12d934e452e1375a2401ef"])
    subscriptions = [a806462fec12d934e452e1375a2401ef: self()]
    relay_url = "my.relay.social"

    :ok = FrameHandler.handle_text_frame(frame, subscriptions, relay_url, self())

    assert_receive {^relay_url, %EndOfStoredEvents{}}
  end

  test "manage an NOTICE frame" do
    message = "timeout: Inactivity timeout, good bye."
    frame = ~s(["NOTICE","#{message}"])
    relay_url = "my.relay.social"
    subscriptions = []

    :ok = FrameHandler.handle_text_frame(frame, subscriptions, relay_url, self())

    assert_receive {:relaysocket, :notice, %{message: ^message, url: ^relay_url}}
  end

  test "manage a parsing error" do
    frame =
      ~s("["EVENT"]")

    relay_url = "my.relay.social"
    subscriptions = [a806462fec12d934e452e1375a2401ef: self()]

    :ok = FrameHandler.handle_text_frame(frame, subscriptions, relay_url, self())

    assert_receive {:relaysocket, :parsing_error, %{frame: ^frame, url: ^relay_url}}
  end
end
