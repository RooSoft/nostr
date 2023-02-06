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
  @spec to_bech32(<<_::256>> | String.t(), String.t()) :: String.t()
  def to_bech32(<<_::256>> = event_id, hrp) do
    Bech32.encode(hrp, event_id)
  end

  def to_bech32(hex_id, hrp) do
    Binary.from_hex(hex_id)
    |> to_bech32(hrp)
  end

  @doc """
  Converts any type of event id into a hex format

  ## Examples
      iex> <<0x2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2::256>>
      ...> |> Nostr.Event.Id.to_hex()
      {:ok, nil, "2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2"}

      iex> "note19e93faw4ffqepsqsrwrnstd3ee00nmzakwwuyfjm43dankgummfqms4p6q"
      ...> |> Nostr.Event.Id.to_hex
      {:ok, "note", "2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2"}
  """
  @spec to_hex(<<_::256>> | binary()) :: {:ok, binary(), <<_::512>>} | {:error, atom()}
  def to_hex(<<_::256>> = event_id) do
    {:ok, nil, Binary.to_hex(event_id)}
  end

  def to_hex(bech32_id) do
    case from_bech32(bech32_id) do
      {:ok, hrp, event_id} -> {:ok, hrp, Binary.to_hex(event_id)}
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  Converts a bech32 event id into a hex string format

  ## Examples
      iex> "note19e93faw4ffqepsqsrwrnstd3ee00nmzakwwuyfjm43dankgummfqms4p6q"
      ...> |> Nostr.Event.Id.to_hex!
      "2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2"
  """
  @spec to_hex!(binary()) :: <<_::512>>
  def to_hex!(bech32_id) do
    from_bech32!(bech32_id)
    |> Binary.to_hex()
  end

  @doc """
  Converts a bech32 event id into its binary format

  ## Examples
      iex> "note19e93faw4ffqepsqsrwrnstd3ee00nmzakwwuyfjm43dankgummfqms4p6q"
      ...> |> Nostr.Event.Id.from_bech32
      {:ok, "note", <<0x2e4b14f5d54a4190c0101b87382db1ce5ef9ec5db39dc2265bac5bd9d91cded2::256>>}
  """
  @spec from_bech32(binary()) :: {:ok, binary(), binary()} | {:error, atom()}
  def from_bech32(bech32_event_id) do
    case Bech32.decode(bech32_event_id) do
      {:ok, hrp, event_id} -> {:ok, hrp, event_id}
      {:error, :no_seperator} -> {:error, "not a valid bech32 identifier"}
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
  Does its best to convert any event id format to binary, issues an error if it can't
  ## Examples
      iex> "note1qkjgra6cm5ms6m88kqdapfjnxm8q50lcurevtpvm4f6pfs8j5sxq90f098"
      ...> |> Nostr.Event.Id.to_binary()
      { :ok, "note", <<0x05a481f758dd370d6ce7b01bd0a65336ce0a3ff8e0f2c5859baa7414c0f2a40c::256>> }
  """
  @spec to_binary(<<_::256>> | String.t() | list()) ::
          {:ok, <<_::256>>} | {:ok, list(<<_::256>>)} | {:error, String.t()}
  def to_binary(<<_::256>> = event_id), do: {:ok, event_id}
  def to_binary(event_id) when is_binary(event_id), do: from_bech32(event_id)

  def to_binary(event_id) when is_list(event_id) do
    event_id
    |> Enum.reverse()
    |> Enum.reduce({:ok, []}, &reduce_to_binaries/2)
  end

  def to_binary(not_lowercase_bech32_event_id) do
    not_lowercase_bech32_event_id
    |> String.downcase()
    |> from_bech32()
  end

  defp reduce_to_binaries(event_id, acc) do
    case acc do
      {:ok, binary_event_ids} ->
        case to_binary(event_id) do
          {:ok, _type, binary_event_id} ->
            {:ok, [binary_event_id | binary_event_ids]}

          {:error, message} ->
            {:error, message}
        end

      {:error, message} ->
        {:error, message}
    end
  end
end
