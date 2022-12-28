defmodule Nostr.Keys.PrivateKey do
  @doc """
  Creates a new private key

  ## Examples
      iex> Nostr.Keys.PrivateKey.create()
  """
  @spec create() :: <<_::256>>
  def create do
    K256.Schnorr.generate_random_signing_key()
  end
end
