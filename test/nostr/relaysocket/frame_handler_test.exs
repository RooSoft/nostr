defmodule Nostr.Client.Relays.RelaySocket.FrameHandlerTest do
  use ExUnit.Case, async: true

  alias Nostr.Client.Relays.RelaySocket.FrameHandler

  test "manage an OK frame" do
    frame = ~s(["OK","a806462fec12d934e452e1375a2401ef",true,"duplicate:"])
    subscriptions = [a806462fec12d934e452e1375a2401ef: self()]
    relay_url = "my.relay.social"

    {:console, :ok,
     %{
       event_id: event_id,
       message: message,
       success?: success?,
       url: received_relay_url
     }} = result = FrameHandler.handle_text_frame(frame, subscriptions, relay_url, self())

    assert event_id == "a806462fec12d934e452e1375a2401ef"
    assert message == "duplicate:"
    assert success?
    assert received_relay_url == relay_url

    assert_receive ^result
  end

  test "manage an EOSE frame" do
    frame = ~s(["EOSE","a806462fec12d934e452e1375a2401ef"])
    subscriptions = [a806462fec12d934e452e1375a2401ef: self()]
    relay_url = "my.relay.social"

    {:end_of_stored_events, received_relay_url, subscription_id} =
      FrameHandler.handle_text_frame(frame, subscriptions, relay_url, self())

    assert subscription_id == "a806462fec12d934e452e1375a2401ef"
    assert received_relay_url == relay_url

    assert_receive {:end_of_stored_events, ^received_relay_url, ^subscription_id}
  end

  test "manage an NOTICE frame" do
    message = "timeout: Inactivity timeout, good bye."
    frame = ~s(["NOTICE","#{message}"])
    relay_url = "my.relay.social"
    subscriptions = []

    {:console, :notice, %{message: received_message, url: received_relay_url}} =
      FrameHandler.handle_text_frame(frame, subscriptions, relay_url, self())

    assert received_message == message
    assert received_relay_url == relay_url

    assert_receive {:console, :notice, %{message: ^message, url: ^relay_url}}
  end

  test "manage a parsing error" do
    frame = ~s(["EVENT")

    relay_url = "my.relay.social"
    subscriptions = [a806462fec12d934e452e1375a2401ef: self()]

    {:console, :malformed_json_relay_message,
     [url: received_relay_url, message: received_message]} =
      result = FrameHandler.handle_text_frame(frame, subscriptions, relay_url, self())

    assert received_relay_url == relay_url
    assert received_message == "error decoding JSON at position 8: "

    assert_receive ^result
  end

  test "manage a contact event" do
    frame =
      ~s(["EVENT","a806462fec12d934e452e1375a2401ef",{"id":"c12c05c4adc8a5ba2fb38c7067735c9cf2336c2aa68fa5100d435a74a345bea5","pubkey":"5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2","created_at":1674247614,"kind":3,"tags":[["p","0000002855ad7906a7568bf4d971d82056994aa67af3cf0048a825415ac90672",""]],"content":"","sig":"2b3dd20798ee1eb2a01442e097689151cc3ded1f368a34114d0bc43a2b5416fb9ae70d984475cd423fc035b8a68f606b5ead5db950ab56a1d6adb311c47fa525"}])

    relay_url = "my.relay.social"
    subscriptions = [a806462fec12d934e452e1375a2401ef: self()]

    {"my.relay.social", "a806462fec12d934e452e1375a2401ef",
     %NostrBasics.Event{
       id: "c12c05c4adc8a5ba2fb38c7067735c9cf2336c2aa68fa5100d435a74a345bea5",
       pubkey: <<0x5AB9F2EFB1FDA6BC32696F6F3FD715E156346175B93B6382099D23627693C3F2::256>>,
       created_at: ~U[2023-01-20 20:46:54Z],
       kind: 3,
       tags: [
         ["p", "0000002855ad7906a7568bf4d971d82056994aa67af3cf0048a825415ac90672", ""]
       ],
       content: "",
       sig:
         <<0x2B3DD20798EE1EB2A01442E097689151CC3DED1F368A34114D0BC43A2B5416FB9AE70D984475CD423FC035B8A68F606B5EAD5DB950AB56A1D6ADB311C47FA525::512>>
     }} = result = FrameHandler.handle_text_frame(frame, subscriptions, relay_url, self())

    assert_receive ^result
  end
end
