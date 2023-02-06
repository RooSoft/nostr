defmodule Nostr.EventTest do
  use ExUnit.Case, async: true

  alias Nostr.Event

  doctest Event

  test "try converting an invalid string to binary note id with to_binary/1" do
    invalid_note_id = "this_won't_work"

    {:error, message} = Event.Id.to_binary(invalid_note_id)

    assert message =~ "not a valid bech32 identifier"
  end

  test "convert a list of bech32 note ids" do
    list = [
      "note1crqskw27zw5p9pyk4r2ask68nlnhn969qhlc32asnwll9557fx4sskrzq5",
      "note1cmr4hn670sf3vxgmma5fv9ewxa5fqlnpelvtppz5z0etlja8xc0s8pkxu6"
    ]

    {:ok, binary_note_ids} = Event.Id.to_binary(list)

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

    {:ok, binary_note_ids} = Event.Id.to_binary(list)

    assert [
             <<0xC0C10B395E13A8128496A8D5D85B479FE779974505FF88ABB09BBFF2D29E49AB::256>>,
             <<0xC6C75BCF5E7C1316191BDF6896172E3768907E61CFD8B0845413F2BFCBA7361F::256>>
           ] == binary_note_ids
  end

  test "attempt converting a list of note ids with errors" do
    list = [
      "note1crqskw27zw5p9pyk4r2ask68nlnhn969qhlc32asnwll9557fx4sskrzq5",
      "note1cmr4hn670setlja8xc0s8pkxu6"
    ]

    {:error, message} = Event.Id.to_binary(list)

    assert :checksum_failed == message
  end
end
