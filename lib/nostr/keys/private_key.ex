defmodule Nostr.Keys.PrivateKey do
  @moduledoc """
  Private keys management functions
  """

  @doc """
  Creates a new private key

  ## Examples
      iex> Nostr.Keys.PrivateKey.create()
  """
  @spec create() :: K256.Schnorr.signing_key()
  def create do
    K256.Schnorr.generate_random_signing_key()
  end

  @doc """
  Extracts a binary private key from the nsec format

  ## Examples
      iex> nsec = "nsec1d4ed5x49d7p24xn63flj4985dc4gpfngdhtqcxpth0ywhm6czxcs5l2exj"
      ...> Nostr.Keys.PrivateKey.from_nsec(nsec)
      {:ok, <<0x6d72da1aa56f82aa9a7a8a7f2a94f46e2a80a6686dd60c182bbbc8ebef5811b1::256>>}
  """
  @spec from_nsec(binary()) :: {:ok, binary()} | {:error, binary()}

  def from_nsec("nsec" <> _ = bech32_private_key) do
    case Bech32.decode(bech32_private_key) do
      {:ok, "nsec", private_key} ->
        if bit_size(private_key) == 256 do
          {:ok, private_key}
        else
          {:error, "private key is shorter than 256 bits"}
        end

      {:ok, _, _} ->
        {:error, "malformed bech32 private key"}

      {:error, message} ->
        {:error, message}

      anything ->
        {:error, anything}
    end
  end

  def from_nsec(badly_formatted_address) do
    {:error, "#{badly_formatted_address} is not an nsec formatted address"}
  end

  @doc """
  Extracts a binary private key from the nsec format

  ## Examples
      iex> nsec = "nsec1d4ed5x49d7p24xn63flj4985dc4gpfngdhtqcxpth0ywhm6czxcs5l2exj"
      ...> Nostr.Keys.PrivateKey.from_nsec!(nsec)
      <<0x6d72da1aa56f82aa9a7a8a7f2a94f46e2a80a6686dd60c182bbbc8ebef5811b1::256>>
  """
  @spec from_nsec!(binary()) :: <<_::256>>
  def from_nsec!("nsec" <> _ = bech32_private_key) do
    case from_nsec(bech32_private_key) do
      {:ok, private_key} -> private_key
      {:error, message} -> raise message
    end
  end

  @doc """
  Encodes a private key into the nsec format

  ## Examples
      iex> private_key = <<0x6d72da1aa56f82aa9a7a8a7f2a94f46e2a80a6686dd60c182bbbc8ebef5811b1::256>>
      ...> Nostr.Keys.PrivateKey.to_nsec(private_key)
      "nsec1d4ed5x49d7p24xn63flj4985dc4gpfngdhtqcxpth0ywhm6czxcs5l2exj"
  """
  @spec to_nsec(<<_::256>>) :: binary()
  def to_nsec(<<_::256>> = private_key) do
    Bech32.encode("nsec", private_key)
  end

  def to_nsec(not_a_256_bits_private_key) do
    {:error, "#{not_a_256_bits_private_key} should be a 256 bits private key"}
  end

  @doc """
  Does its best to convert any private key format to binary, issues an error if it can't

  ## Examples
      iex> "nsec1fc3d5s6p3hvngdeuhvu2t2cnqkgerg4n55w9uzm8avfngetfgwuqc25heg"
      ...> |> Nostr.Keys.PrivateKey.to_binary()
      { :ok, <<0x4e22da43418dd934373cbb38a5ab13059191a2b3a51c5e0b67eb1334656943b8::256>> }
  """
  @spec to_binary(<<_::256>> | String.t()) :: {:ok, <<_::256>>} | {:error, String.t()}
  def to_binary(<<_::256>> = private_key), do: {:ok, private_key}
  def to_binary("nsec" <> _ = private_key), do: from_nsec(private_key)

  def to_binary(not_lowercase_nsec) do
    case String.downcase(not_lowercase_nsec) do
      "nsec" <> _ = nsec -> from_nsec(nsec)
      _ -> {:error, "#{not_lowercase_nsec} is not a valid private key"}
    end
  end

  @doc """
  Does its best to convert any private key format to binary, raises an error if it can't

  ## Examples
      iex> "nsec1fc3d5s6p3hvngdeuhvu2t2cnqkgerg4n55w9uzm8avfngetfgwuqc25heg"
      ...> |> Nostr.Keys.PrivateKey.to_binary!()
      <<0x4e22da43418dd934373cbb38a5ab13059191a2b3a51c5e0b67eb1334656943b8::256>>
  """
  @spec to_binary!(<<_::256>> | String.t()) :: <<_::256>>
  def to_binary!(private_key) do
    case to_binary(private_key) do
      {:ok, binary_private_key} -> binary_private_key
      {:error, :checksum_failed} -> raise "checkum failed"
      {:error, message} -> raise message
    end
  end
end
