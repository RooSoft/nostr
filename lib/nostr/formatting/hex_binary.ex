defmodule Nostr.Formatting.HexBinary do
  @moduledoc """
  A way to represent binaries in a human readable format that fits
  what's found on the web related to keys and addresses

  Example:

    <<0x181DCB172F5B56DB39B6C8544068FEE69928556230B41E115BDB22BF82A06FF3::256>>

    instead of

    <<24, 29, 203, 23, 47, 91, 86, 219, 57, 182, 200, 84, 64, 104, 254, 230, 153, 40, 85, 98, 48, 180, 30, 17, 91, 219, 34, 191, 130, 160, 111, 243>>
  """
  defstruct [:data]

  alias Nostr.Formatting.HexBinary

  @doc """
  Constructor
  """
  def from_binary(data) when is_binary(data) do
    %HexBinary{data: data}
  end
end

defimpl Inspect, for: Nostr.Formatting.HexBinary do
  @byte 8

  def inspect(%Nostr.Formatting.HexBinary{} = binary, _opts) do
    print_compact_bitstring(binary.data)
  end

  defp print_compact_bitstring(bitstring) do
    hex_data = Base.encode16(bitstring, case: :lower)
    data_size = byte_size(bitstring) * @byte

    "<<0x#{hex_data}::#{data_size}>>"
  end
end
