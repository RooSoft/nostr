defmodule Nostr.Keys.PublicKeyTest do
  use ExUnit.Case, async: true

  alias Nostr.Keys.PublicKey

  doctest PublicKey

  test "convert an npub with to_binary/1" do
    npub = "npub1hycynfhz23ardfmf9kgwfw4gpyqj2fsh24r2zuehg4x7lx4kn5cqsqv4y3"

    {:ok, binary_public_key} = PublicKey.to_binary(npub)

    assert <<0xB93049A6E2547A36A7692D90E4BAA809012526175546A17337454DEF9AB69D30::256>> ==
             binary_public_key
  end

  test "convert a binary to binary with to_binary/1" do
    public_key = <<0xB93049A6E2547A36A7692D90E4BAA809012526175546A17337454DEF9AB69D30::256>>

    {:ok, binary_public_key} = PublicKey.to_binary(public_key)

    assert public_key == binary_public_key
  end
end
