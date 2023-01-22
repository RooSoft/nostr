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
  @spec to_hex(<<_::256>> | String.t()) :: {:ok, <<_::512>>} | {:error, atom()}
  def to_hex(@hrp <> _ = bech32_note_id) do
    case Event.Id.to_hex(bech32_note_id) do
      {:ok, @hrp, <<_::512>> = id} -> {:ok, id}
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
  @spec from_bech32(binary()) :: {:ok, binary()} | {:error, atom()}
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

  @doc """
  Does its best to convert any note id format to binary, issues an error if it can't

  ## Examples
      iex> "note1qkjgra6cm5ms6m88kqdapfjnxm8q50lcurevtpvm4f6pfs8j5sxq90f098"
      ...> |> Nostr.Models.Note.Id.to_binary()
      { :ok, <<0x05a481f758dd370d6ce7b01bd0a65336ce0a3ff8e0f2c5859baa7414c0f2a40c::256>> }
  """
  @spec to_binary(<<_::256>> | String.t() | list()) ::
          {:ok, <<_::256>>} | {:ok, list(<<_::256>>)} | {:error, String.t()}
  def to_binary(<<_::256>> = note_id), do: {:ok, note_id}
  def to_binary("note" <> _ = note_id), do: from_bech32(note_id)

  def to_binary(note_ids) when is_list(note_ids) do
    note_ids
    |> Enum.reverse()
    |> Enum.reduce({:ok, []}, fn note_id, {:ok, binary_note_ids} ->
      case to_binary(note_id) do
        {:ok, binary_note_id} ->
          {:ok, [binary_note_id | binary_note_ids]}

        {:error, message} ->
          {:error, message}
      end
    end)
  end

  def to_binary(not_lowercase_bech32_note_id) do
    case String.downcase(not_lowercase_bech32_note_id) do
      "note" <> _ = bech32_note_id -> from_bech32(bech32_note_id)
      _ -> {:error, "#{not_lowercase_bech32_note_id} is not a valid note id"}
    end
  end
end
