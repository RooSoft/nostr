defmodule Nostr.Event.Signer do
  alias Nostr.Event
  alias K256.Schnorr

  @doc """
  Applies the schnorr signatures to an event and adds signature to it if successful
  """
  # TODO: must fix the k256 lib so we can remove this dialyzer nowarn statement
  @dialyzer {:nowarn_function, sign_event: 2}
  @spec sign_event(%Event{}, <<_::256>>) :: {:ok, binary()} | {:error, binary()}
  def sign_event(%Event{id: _id} = event, <<_::256>> = privkey) do
    json_for_id = Event.json_for_id(event)

    case Schnorr.create_signature(json_for_id, privkey) do
      {:ok, sig} -> {:ok, %{event | sig: sig}}
      {:error, message} -> {:error, message}
    end
  end
end
