defmodule Nostr.Integration.SignAndVerifyTest do
  use ExUnit.Case, async: true

  alias Nostr.Event.{Signer, Validator}
  alias Nostr.Event
  alias K256.Schnorr

  @test_private_key <<0x4E22DA43418DD934373CBB38A5AB13059191A2B3A51C5E0B67EB1334656943B8::256>>

  setup_all do
    %{
      private_key: @test_private_key,
      event: %Event{
        content:
          "Making sure the schnorr signature included with notes correspond to the public key",
        tags: [
          ["e", "4aa1f23601bb6c7275dca98bbfb6df593caeef0696f1ed260a0cb406d74d1fb0"],
          ["e", "0500f45ca79ecf3a6e4dd6ecfd6a8c2ef2fedf8c590e60b22b98196a89ee2560"],
          ["p", "98b62941fc20cfbb094e54b33593afa0090e43f263e92689a0b66b7e97cf39de"]
        ],
        pubkey:
          Schnorr.verifying_key_from_signing_key(@test_private_key)
          |> elem(1),
        created_at: ~U[2022-12-25 16:33:04Z],
        kind: 1
      }
    }
  end

  test "sign and validate", %{event: event, private_key: private_key} do
    event_with_id = Event.add_id(event)

    case Signer.sign_event(event_with_id, private_key) do
      {:ok, signed_event} ->
        assert :ok = Validator.validate_event(signed_event)

      {:error, _message} ->
        assert false
    end
  end
end
