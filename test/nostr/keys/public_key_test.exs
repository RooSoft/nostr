defmodule Nostr.Keys.PublicKeyTest do
  use ExUnit.Case, async: true

  alias Nostr.Keys.PublicKey

  doctest PublicKey

  test "from an nsec private key" do
    nsec = "nsec1fc3d5s6p3hvngdeuhvu2t2cnqkgerg4n55w9uzm8avfngetfgwuqc25heg"

    {:ok, public_key} = PublicKey.from_private_key(nsec)

    assert <<0x5AB9F2EFB1FDA6BC32696F6F3FD715E156346175B93B6382099D23627693C3F2::256>> ==
             public_key
  end

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

  test "try converting an invalid string to binary with to_binary/1" do
    invalid_public_key = "this_won't_work"

    {:error, message} = PublicKey.to_binary(invalid_public_key)

    assert message =~ "is not a valid public key"
  end

  test "convert a list of npub to binary ids" do
    list = [
      "npub1tv8gmfhalwnxxquxjzeh6gtdsdz6vg7vx0s3rt7s7uuw6aujh32qn77wn2",
      "npub1ate84ggysvau69hkw9ygkqwktak6xqtrkkzg465eva7vj37aqz4qqwmf3z"
    ]

    {:ok, binary_public_keys} = PublicKey.to_binary(list)

    assert [
             <<0x5B0E8DA6FDFBA663038690B37D216D8345A623CC33E111AFD0F738ED7792BC54::256>>,
             <<0xEAF27AA104833BCD16F671488B01D65F6DA30163B5848AEA99677CC947DD00AA::256>>
           ] == binary_public_keys
  end

  test "convert a disparate list of public key formats to binary ids" do
    list = [
      <<0x5B0E8DA6FDFBA663038690B37D216D8345A623CC33E111AFD0F738ED7792BC54::256>>,
      "npub1ate84ggysvau69hkw9ygkqwktak6xqtrkkzg465eva7vj37aqz4qqwmf3z"
    ]

    {:ok, binary_public_keys} = PublicKey.to_binary(list)

    assert [
             <<0x5B0E8DA6FDFBA663038690B37D216D8345A623CC33E111AFD0F738ED7792BC54::256>>,
             <<0xEAF27AA104833BCD16F671488B01D65F6DA30163B5848AEA99677CC947DD00AA::256>>
           ] == binary_public_keys
  end

  test "attempt converting a list of public keys with errors" do
    list = [
      "npub1tv8gmg7vx0s3rt7s7uuw6aujh32qn77wn2",
      "npub1ate84ggysvau69hkw9ygkqwktak6xqtrkkzg465eva7vj37aqz4qqwmf3z"
    ]

    {:error, message} = PublicKey.to_binary(list)

    assert :checksum_failed == message
  end
end
