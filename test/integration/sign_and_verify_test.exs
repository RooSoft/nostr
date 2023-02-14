defmodule Nostr.Integration.SignAndVerifyTest do
  use ExUnit.Case, async: true

  alias NostrBasics.Event
  alias NostrBasics.Event.{Signer, Validator}
  alias NostrBasics.Keys.PublicKey

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
        pubkey: PublicKey.from_private_key!(@test_private_key),
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

  test "validate a reaction" do
    # event = %Nostr.Event{
    #   id: "7b520511bdcb06a4dce4440a57528083243aaa1c77e72843c96f997ccb4222a5",
    #   pubkey: <<0x5AB9F2EFB1FDA6BC32696F6F3FD715E156346175B93B6382099D23627693C3F2::256>>,
    #   created_at: ~U[2023-01-11 20:06:57Z],
    #   kind: 7,
    #   tags: [
    #     ["e", "ec9f6408befea8b9be19930201654d382c60bcdd9c5ca94620e0a5891492a0a0"],
    #     ["p", "4613d320aa8802792a5a2f3349a2207e32f671e8c0400580ddc30eda6fddf62a"]
    #   ],
    #   content: "+",
    #   sig:
    #     <<0x3769EADFAC12E7BCCEEE97B7519EF283303BB4FB6D8B9F6A2CE7044B8941139557DEA3D9091BC571DDE8C9E2EA1BCD85EFC4F04F28A6EA0409EF73EF82DB7705::512>>
    # }

    event = %Event{
      id: "76de8fef03eda5ba3ff5eda7eeef7b9a0b2d7cc6dc13242702ddc9fa93d15edd",
      pubkey: <<0x5AB9F2EFB1FDA6BC32696F6F3FD715E156346175B93B6382099D23627693C3F2::256>>,
      created_at: ~U[2023-01-11 20:06:57Z],
      kind: 7,
      tags: [
        ["e", "e84e687d6c26840b2315118cf7689a0abc8887f76077208c1a7d3253fe44bd4c"],
        ["p", "d307643547703537dfdef811c3dea96f1f9e84c8249e200353425924a9908cf8"]
      ],
      content: "+",
      sig:
        <<0x0317012E0E66506EBCC6A62C145AB1E9FD430C352DAC3E53A855453C8624BA1755A29C5A0B43DF193B1850EB7D56ABE236F51A1E99BF9411E1BB9C0C63BED8B2::512>>
    }

    id_result = Event.Validator.validate_id(event)
    sig_result = Event.Validator.validate_signature(event)

    assert :ok == id_result
    assert :ok == sig_result
  end
end
