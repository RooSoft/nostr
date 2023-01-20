defmodule Nostr.Keys.PrivateKeyTest do
  use ExUnit.Case, async: true

  alias Nostr.Keys.PrivateKey

  doctest PrivateKey

  test "convert an nsec with to_binary/1" do
    nsec = "nsec1fc3d5s6p3hvngdeuhvu2t2cnqkgerg4n55w9uzm8avfngetfgwuqc25heg"

    {:ok, binary_private_key} = PrivateKey.to_binary(nsec)

    assert <<0x4E22DA43418DD934373CBB38A5AB13059191A2B3A51C5E0B67EB1334656943B8::256>> ==
             binary_private_key
  end

  test "convert a binary to binary with to_binary/1" do
    private_key = <<0x4E22DA43418DD934373CBB38A5AB13059191A2B3A51C5E0B67EB1334656943B8::256>>

    {:ok, binary_private_key} = PrivateKey.to_binary(private_key)

    assert private_key == binary_private_key
  end

  test "try converting an invalid string to binary with to_binary/1" do
    invalid_private_key = "this_won't_work"

    {:error, message} = PrivateKey.to_binary(invalid_private_key)

    assert message =~ "is not a valid private key"
  end

  test "convert an nsec with to_binary!/1" do
    nsec = "nsec1fc3d5s6p3hvngdeuhvu2t2cnqkgerg4n55w9uzm8avfngetfgwuqc25heg"

    binary_private_key = PrivateKey.to_binary!(nsec)

    assert <<0x4E22DA43418DD934373CBB38A5AB13059191A2B3A51C5E0B67EB1334656943B8::256>> ==
             binary_private_key
  end

  test "convert an nsec with to_binary!/1 that raises an error" do
    nsec = "nsec1fc3d5s6p3hvngdgwuqc25heg"

    assert_raise RuntimeError, fn ->
      PrivateKey.to_binary!(nsec)
    end
  end
end
