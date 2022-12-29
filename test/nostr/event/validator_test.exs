defmodule Nostr.Event.ValidatorTest do
  use ExUnit.Case, async: true

  alias Nostr.Event.Validator
  alias Nostr.Event

  setup_all do
    %{
      event: %Event{
        id: "c87a24fc125871887a632dd069b7a510bbf987fe7210f3e5bc67492ef461d87d",
        content:
          "Making sure the schnorr signature included with notes correspond to the public key",
        tags: [
          ["e", "4aa1f23601bb6c7275dca98bbfb6df593caeef0696f1ed260a0cb406d74d1fb0"],
          ["e", "0500f45ca79ecf3a6e4dd6ecfd6a8c2ef2fedf8c590e60b22b98196a89ee2560"],
          ["p", "98b62941fc20cfbb094e54b33593afa0090e43f263e92689a0b66b7e97cf39de"]
        ],
        pubkey: <<0xEFC83F01C8FB309DF2C8866B8C7924CC8B6F0580AFDDE1D6E16E2B6107C2862C::256>>,
        sig:
          <<0x1073EB38BA54982BF7A92139CECF23959D8CF6900EC44474BCECD9882B32F70AFEADFDA20620B1436F3CE9680A62261F126B92A5314FA27A4B0EAB8F2447EABD::512>>,
        created_at: ~U[2022-12-25 16:33:04Z],
        kind: 1
      }
    }
  end

  test "validate a note", %{event: event} do
    validation_result = Validator.validate_event(event)

    assert :ok = validation_result
  end

  test "validate a note's id", %{event: event} do
    validation_result = Validator.validate_id(event)

    assert :ok = validation_result
  end

  test "validate a note's signature", %{event: event} do
    validation_result = Validator.validate_signature(event)

    assert :ok = validation_result
  end
end
