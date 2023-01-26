defmodule Nostr.Client.Relays.RelaySocket.FrameHandlerTest do
  use ExUnit.Case, async: true

  alias Nostr.Client.Relays.RelaySocket.FrameHandler
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

    assert_receive {:console, :notice, %{message: ^message, url: ^relay_url}}
  end

  test "manage a parsing error" do
    frame = ~s("["EVENT"]")

    relay_url = "my.relay.social"
    subscriptions = [a806462fec12d934e452e1375a2401ef: self()]

    :ok = FrameHandler.handle_text_frame(frame, subscriptions, relay_url, self())

    assert_receive {:console, :parsing_error, %{frame: ^frame, url: ^relay_url}}
  end

  test "manage a contact event" do
    frame =
      ~s(["EVENT","a806462fec12d934e452e1375a2401ef",{"id":"c12c05c4adc8a5ba2fb38c7067735c9cf2336c2aa68fa5100d435a74a345bea5","pubkey":"5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2","created_at":1674247614,"kind":3,"tags":[["p","0000002855ad7906a7568bf4d971d82056994aa67af3cf0048a825415ac90672",""]],"content":"","sig":"2b3dd20798ee1eb2a01442e097689151cc3ded1f368a34114d0bc43a2b5416fb9ae70d984475cd423fc035b8a68f606b5ead5db950ab56a1d6adb311c47fa525"}])

    relay_url = "my.relay.social"
    subscriptions = [a806462fec12d934e452e1375a2401ef: self()]

    :ok = FrameHandler.handle_text_frame(frame, subscriptions, relay_url, self())

    assert_receive {"my.relay.social",
                    %Nostr.Models.ContactList{
                      id: "c12c05c4adc8a5ba2fb38c7067735c9cf2336c2aa68fa5100d435a74a345bea5",
                      pubkey:
                        <<0x5AB9F2EFB1FDA6BC32696F6F3FD715E156346175B93B6382099D23627693C3F2::256>>,
                      created_at: ~U[2023-01-20 20:46:54Z],
                      contacts: [
                        %Nostr.Models.Contact{
                          pubkey:
                            <<0x0000002855AD7906A7568BF4D971D82056994AA67AF3CF0048A825415AC90672::256>>,
                          main_relay: "",
                          petname: nil
                        }
                      ]
                    }}
  end
end
