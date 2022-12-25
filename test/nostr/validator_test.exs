defmodule Nostr.ValidatorTest do
  use ExUnit.Case, async: true

  alias Nostr.Validator

  setup_all do
    %{
      text_event: %Nostr.Event.TextEvent{
        id: "c95f0243f8416c2261d306ff21d114e7b4bf336e4b844ccbc968ab2feea6dfa0",
        content: "Been building on nostr all day... still do",
        tags: [],
        pubkey: "efc83f01c8fb309df2c8866b8c7924cc8b6f0580afdde1d6e16e2b6107c2862c",
        sig:
          "2b694dfb688b74e1544db501fbf7b4cde78ce233235660f319b2c82e2d2a403cc000f8a015cae38f743585d1a81321d223a61bcc11d895277039e31c2b0028f2",
        created_at: ~U[2022-12-23 01:56:18Z]
      }
    }
  end

  test "validate a note's signature", %{text_event: text_event} do
    validation_result = Validator.validate_note(text_event)

    assert :ok = validation_result
  end
end
