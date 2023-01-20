defmodule Nostr.Models.Note.IdTest do
  use ExUnit.Case

  alias Nostr.Models.Note

  doctest Note.Id

  test "convert an bech32 note id with to_binary/1" do
    bech32_note_id = "note1qkjgra6cm5ms6m88kqdapfjnxm8q50lcurevtpvm4f6pfs8j5sxq90f098"

    {:ok, note_id} = Note.Id.to_binary(bech32_note_id)

    assert <<0x05A481F758DD370D6CE7B01BD0A65336CE0A3FF8E0F2C5859BAA7414C0F2A40C::256>> == note_id
  end

  test "convert a binary note id to binary with to_binary/1" do
    note_id = <<0x05A481F758DD370D6CE7B01BD0A65336CE0A3FF8E0F2C5859BAA7414C0F2A40C::256>>

    {:ok, binary_note_id} = Note.Id.to_binary(note_id)

    assert note_id == binary_note_id
  end

  test "try converting an invalid string to binary note id with to_binary/1" do
    invalid_note_id = "this_won't_work"

    {:error, message} = Note.Id.to_binary(invalid_note_id)

    assert message =~ "is not a valid note id"
  end
end
