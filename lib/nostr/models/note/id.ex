defmodule Nostr.Models.Note.Id do
  @moduledoc """
  Note id conversion functions
  """

  @hrp "note"

  alias Nostr.Event

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
  @spec to_bech32(binary()) :: binary()
  def to_bech32(note_id) do
    Event.Id.to_bech32(note_id, @hrp)
  end

  @doc """
  Converts a note binary id into a hex format

  ## Examples
      iex> <<0x2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2::256>>
      ...> |> Nostr.Models.Note.Id.to_hex()
      {:ok, "2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2"}

      iex> "note19e93faw4ffqepsqsrwrnstd3ee00nmzakwwuyfjm43dankgummfqms4p6q"
      ...> |> Nostr.Models.Note.Id.to_hex()
      {:ok, "2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2"}
  """
  @spec to_hex(<<_::256>> | binary()) :: {:ok, <<_::512>>} | {:error, binary()}
  def to_hex(@hrp <> _ = bech32_note_id) do
    case Event.Id.to_hex(bech32_note_id) do
      {:ok, @hrp, id} -> {:ok, id}
      {:ok, type, _id} -> {:error, "tried to convert a bech32 #{type} id into a note"}
      {:error, message} -> {:error, message}
    end
  end

  def to_hex(note_id) do
    {:ok, _, hex} = Event.Id.to_hex(note_id)

    {:ok, hex}
  end

  @doc """
  Converts a bech32 note id into a hex string format

  ## Examples
      iex> "note19e93faw4ffqepsqsrwrnstd3ee00nmzakwwuyfjm43dankgummfqms4p6q"
      ...> |> Nostr.Models.Note.Id.to_hex!
      "2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2"
  """
  @spec to_hex!(binary()) :: <<_::512>>
  def to_hex!(@hrp <> _ = bech32_note_id) do
    Event.Id.to_hex!(bech32_note_id)
  end

  @doc """
  Converts a bech32 note id into its binary format

  ## Examples
      iex> "note19e93faw4ffqepsqsrwrnstd3ee00nmzakwwuyfjm43dankgummfqms4p6q"
      ...> |> Nostr.Models.Note.Id.from_bech32
      {:ok, <<0x2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2::256>>}
  """
  @spec from_bech32(binary()) :: {:ok, <<_::256>>} | {:error, binary()}
  def from_bech32(@hrp <> _ = bech32_note_id) do
    case Event.Id.from_bech32(bech32_note_id) do
      {:ok, @hrp, id} -> {:ok, id}
      {:ok, type, _id} -> {:error, "tried to convert a bech32 #{type} id into a note"}
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  Converts a bech32 note id into its binary format

  ## Examples
      iex> "note19e93faw4ffqepsqsrwrnstd3ee00nmzakwwuyfjm43dankgummfqms4p6q"
      ...> |> Nostr.Models.Note.Id.from_bech32!
      <<0x2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2::256>>
  """
  @spec from_bech32!(binary()) :: <<_::256>>
  def from_bech32!(@hrp <> _ = bech32_note_id) do
    Event.Id.from_bech32!(bech32_note_id)
  end
end
