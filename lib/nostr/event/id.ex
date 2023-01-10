defmodule Nostr.Event.Id do
  @moduledoc """
  Event id conversion functions
  """

  @doc """
  Converts an event binary id into a bech32 format

  ## Examples
      iex> <<0x2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2::256>>
      ...> |> Nostr.Event.Id.to_bech32("note")
      "note19e93faw4ffqepsqsrwrnstd3ee00nmzakwwuyfjm43dankgummfqms4p6q"

      iex> "2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2"
      ...> |> Nostr.Event.Id.to_bech32("note")
      "note19e93faw4ffqepsqsrwrnstd3ee00nmzakwwuyfjm43dankgummfqms4p6q"
  """
  @spec to_bech32(<<_::256>>, binary()) :: binary()
  def to_bech32(<<_::256>> = event_id, hrp) do
    Bech32.encode(hrp, event_id)
  end

  @spec to_bech32(binary(), binary()) :: binary()
  def to_bech32(hex_id, hrp) do
    Binary.from_hex(hex_id)
    |> to_bech32(hrp)
  end

  @doc """
  Converts an event binary id into a hex format

  ## Examples
      iex> <<0x2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2::256>>
      ...> |> Nostr.Event.Id.to_hex()
      "2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2"
  """
  @spec to_hex(<<_::256>>) :: <<_::512>>
  def to_hex(<<_::256>> = event_id) do
    Binary.to_hex(event_id)
  end

  @doc """
  Converts a bech32 event id into its binary format

  ## Examples
      iex> "note19e93faw4ffqepsqsrwrnstd3ee00nmzakwwuyfjm43dankgummfqms4p6q"
      ...> |> Nostr.Event.Id.from_bech32
      {:ok, "note", <<0x2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2::256>>}
  """
  @spec from_bech32(binary()) :: {:ok, binary(), <<_::256>>} | {:error, binary()}
  def from_bech32(bech32_event_id) do
    case Bech32.decode(bech32_event_id) do
      {:ok, hrp, event_id} -> {:ok, hrp, event_id}
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  Converts a bech32 event id into its binary format

  ## Examples
      iex> "note19e93faw4ffqepsqsrwrnstd3ee00nmzakwwuyfjm43dankgummfqms4p6q"
      ...> |> Nostr.Event.Id.from_bech32!
      <<0x2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2::256>>
  """
  @spec from_bech32!(binary()) :: <<_::256>>
  def from_bech32!(bech32_id) do
    case from_bech32(bech32_id) do
      {:ok, _hrp, event_id} -> event_id
      {:error, message} -> raise message
    end
  end

  @doc """
  Converts a bech32 event id into a hex string format

  ## Examples
      iex> "note19e93faw4ffqepsqsrwrnstd3ee00nmzakwwuyfjm43dankgummfqms4p6q"
      ...> |> Nostr.Event.Id.from_bech32_to_hex
      {:ok, "note", "2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2"}
  """
  @spec from_bech32_to_hex(binary()) :: <<_::512>>
  def from_bech32_to_hex(bech32_id) do
    case from_bech32(bech32_id) do
      {:ok, hrp, event_id} -> {:ok, hrp, Binary.to_hex(event_id)}
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  Converts a bech32 event id into a hex string format

  ## Examples
      iex> "note19e93faw4ffqepsqsrwrnstd3ee00nmzakwwuyfjm43dankgummfqms4p6q"
      ...> |> Nostr.Event.Id.from_bech32_to_hex!
      "2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2"
  """
  @spec from_bech32_to_hex!(binary()) :: <<_::512>>
  def from_bech32_to_hex!(bech32_id) do
    from_bech32!(bech32_id)
    |> Binary.to_hex()
  end
end
