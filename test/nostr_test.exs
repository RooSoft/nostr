defmodule NostrTest do
  @moduledoc """
  Based on https://github.com/bitcoin/bips/blob/master/bip-0340/test-vectors.csv
  """
  use ExUnit.Case
  doctest Nostr

  test "sign a message based on the first bip340 test vector" do
    secret_key = <<0x0000000000000000000000000000000000000000000000000000000000000003::256>>
    message = "0000000000000000000000000000000000000000000000000000000000000000"

    real_signature =
      <<0xE907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA821525F66A4A85EA8B71E482A74F382D2CE5EBEEE8FDB2172F477DF4900D310536C0::512>>

    signature = Nostr.sign_message(message, secret_key)

    assert real_signature == signature
  end
end
