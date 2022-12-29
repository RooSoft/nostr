defmodule Nostr.Keys.PrivateKey do
  @doc """
  Creates a new private key

  ## Examples
      iex> Nostr.Keys.PrivateKey.create()
  """
  # TODO: must fix the k256 lib so we can remove this dialyzer nowarn statement
  @dialyzer {:nowarn_function, create: 0}
  @spec create() :: <<_::256>>
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
      {:ok, "nsec", private_key} -> {:ok, private_key}
      {:ok, _, _} -> {:error, "malformed bech32 private key"}
      {:error, message} -> {:error, message}
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
end
