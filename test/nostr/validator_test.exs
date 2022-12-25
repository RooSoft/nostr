defmodule Nostr.ValidatorTest do
  use ExUnit.Case, async: true

  alias Nostr.Validator
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
        pubkey: "efc83f01c8fb309df2c8866b8c7924cc8b6f0580afdde1d6e16e2b6107c2862c",
        sig:
          "1073eb38ba54982bf7a92139cecf23959d8cf6900ec44474bcecd9882b32f70afeadfda20620b1436f3ce9680a62261f126b92a5314fa27a4b0eab8f2447eabd",
        created_at: ~U[2022-12-25 16:33:04Z]
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
