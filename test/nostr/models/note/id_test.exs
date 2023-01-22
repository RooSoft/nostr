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

  test "convert a list of bech32 note ids" do
    list = [
      "note1crqskw27zw5p9pyk4r2ask68nlnhn969qhlc32asnwll9557fx4sskrzq5",
      "note1cmr4hn670sf3vxgmma5fv9ewxa5fqlnpelvtppz5z0etlja8xc0s8pkxu6"
    ]

    {:ok, binary_note_ids} = Note.Id.to_binary(list)

    assert [
             <<0xC0C10B395E13A8128496A8D5D85B479FE779974505FF88ABB09BBFF2D29E49AB::256>>,
             <<0xC6C75BCF5E7C1316191BDF6896172E3768907E61CFD8B0845413F2BFCBA7361F::256>>
           ] == binary_note_ids
  end

  test "convert a disparate list of note ids into binaries" do
    list = [
      "note1crqskw27zw5p9pyk4r2ask68nlnhn969qhlc32asnwll9557fx4sskrzq5",
      "note1cmr4hn670sf3vxgmma5fv9ewxa5fqlnpelvtppz5z0etlja8xc0s8pkxu6"
    ]

    {:ok, binary_note_ids} = Note.Id.to_binary(list)

    assert [
             <<0xC0C10B395E13A8128496A8D5D85B479FE779974505FF88ABB09BBFF2D29E49AB::256>>,
             <<0xC6C75BCF5E7C1316191BDF6896172E3768907E61CFD8B0845413F2BFCBA7361F::256>>
           ] == binary_note_ids
  end
end
