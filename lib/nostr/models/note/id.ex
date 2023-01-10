defmodule Nostr.Models.Note.Id do
  @moduledoc """
  Note id conversion functions
  """

  @hrp "note"

  @doc """
  Converts a note binary id into a bech32 format

  ## Examples
      iex> <<0x2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2::256>>
      ...> |> Nostr.Models.Note.Id.to_bech32()
      "note19e93faw4ffqepsqsrwrnstd3ee00nmzakwwuyfjm43dankgummfqms4p6q"

      iex> "2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2"
      ...> |> Nostr.Models.Note.Id.to_bech32()
      "note19e93faw4ffqepsqsrwrnstd3ee00nmzakwwuyfjm43dankgummfqms4p6q"
  """
  @spec to_bech32(<<_::256>>) :: binary()
  def to_bech32(<<_::256>> = note_id) do
    Bech32.encode(@hrp, note_id)
  end

  @spec to_bech32(binary()) :: binary()
  def to_bech32(hex_note_id) do
    Binary.from_hex(hex_note_id)
    |> to_bech32()
  end

  @spec to_hex(<<_::256>>) :: <<_::512>>
  def to_hex(<<_::256>> = note_id) do
    Binary.to_hex(note_id)
  end

  @spec from_bech32(binary()) :: {:ok, <<_::256>>} | {:error, binary()}
  def from_bech32(@hrp <> _ = bech32_note_id) do
    case Bech32.decode(bech32_note_id) do
      {:ok, @hrp, note_id} -> {:ok, note_id}
      {:ok, _, _} -> {:error, "malformed bech32 note id"}
      {:error, message} -> {:error, message}
    end
  end

  @spec from_bech32!(binary()) :: <<_::256>>
  def from_bech32!(@hrp <> _ = bech32_note_id) do
    case from_bech32(bech32_note_id) do
      {:ok, note_id} -> note_id
      {:error, message} -> raise message
    end
  end

  @spec from_bech32_to_hex(binary()) :: <<_::512>>
  def from_bech32_to_hex(@hrp <> _ = bech32_note_id) do
    case from_bech32(bech32_note_id) do
      {:ok, note_id} -> {:ok, Binary.to_hex(note_id)}
      {:error, message} -> {:error, message}
    end
  end

  @spec from_bech32_to_hex!(binary()) :: <<_::512>>
  def from_bech32_to_hex!(@hrp <> _ = bech32_note_id) do
    from_bech32!(bech32_note_id)
    |> Binary.to_hex()
  end
end
