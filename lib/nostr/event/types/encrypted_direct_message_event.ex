defmodule Nostr.Event.Types.EncryptedDirectMessageEvent do
  require Logger

  defstruct [:decrypted, :decryption_error, event: %Nostr.Event{}]

  alias Nostr.Event
  alias Nostr.Event.Types.EncryptedDirectMessageEvent

  @kind 4

  @spec create(binary(), K256.Schnorr.verifying_key(), K256.Schnorr.verifying_key()) ::
          %EncryptedDirectMessageEvent{}
  def create(content, local_pubkey, remote_pubkey) do
    tags = [["p", remote_pubkey |> Binary.to_hex()]]

    event =
      %{Event.create(content, local_pubkey) | kind: @kind, tags: tags}
      |> Event.add_id()

    %EncryptedDirectMessageEvent{event: event}
  end

  def parse(%{"content" => content} = body) do
    event = %{Event.parse(body) | content: content}

    case event.kind do
      @kind ->
        {:ok, %EncryptedDirectMessageEvent{event: event}}

      kind ->
        {:error,
         "Tried to parse a encrypted direct message event with kind #{kind} instead of #{@kind}"}
    end
  end
end
