defmodule Nostr.Models.EncryptedDirectMessage.Convert do
  alias NostrBasics.Keys.{PrivateKey, PublicKey}
  alias NostrBasics.Event
  alias NostrBasics.Crypto.AES256CBC

  alias Nostr.Models.EncryptedDirectMessage

  @encrypted_direct_message_kind 4

  @doc """
  Creates a new nostr encrypted direct message

  The example below gets rid of the encrypted message, as it is non-deterministic and is thus impossible to test

  Here is an example of what it might look like:

  ```
  OpilDmCQZhLK7G6b5zmIwgCX6MEfP2cFkoV4H3a/UbMD9cmYEGowGkY5Cxz4tljFUgmaC4SPC/C9dAgrgRVXh42/qTFTfDYRfAe30VcDR/0=?iv=NLUOJc1zy9EKukMYXTkRDg==
  ```

  ## Examples
      iex> {:ok, event} = %Nostr.Models.EncryptedDirectMessage{
      ...>   content: "The Times 03/Jan/2009 Chancellor on brink of second bailout for banks",
      ...>   remote_pubkey: <<0xefc83f01c8fb309df2c8866b8c7924cc8b6f0580afdde1d6e16e2b6107c2862c::256>>
      ...> }
      ...> |> Nostr.Models.EncryptedDirectMessage.Convert.to_event(<<0x4E22DA43418DD934373CBB38A5AB13059191A2B3A51C5E0B67EB1334656943B8::256>>)
      ...> %NostrBasics.Event{event | content: nil}
      %NostrBasics.Event{
        pubkey: <<0x5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2::256>>,
        kind: 4,
        tags: [
          ["p", "efc83f01c8fb309df2c8866b8c7924cc8b6f0580afdde1d6e16e2b6107c2862c"]
        ]
      }
  """
  @spec to_event(Note.t(), PrivateKey.t()) :: {:ok, Event.t()} | {:error, String.t()}
  def to_event(
        %EncryptedDirectMessage{content: content, remote_pubkey: remote_pubkey},
        signing_private_key
      ) do
    with {:ok, binary_signing_pubkey} <- PublicKey.from_private_key(signing_private_key),
         {:ok, binary_remote_pubkey} <- PublicKey.to_binary(remote_pubkey) do
      hex_remote_pubkey = PublicKey.to_hex(binary_remote_pubkey)

      encrypted_message = AES256CBC.encrypt(content, binary_signing_pubkey, binary_remote_pubkey)
      tags = [["p", hex_remote_pubkey]]

      {
        :ok,
        %{
          Event.create(@encrypted_direct_message_kind, encrypted_message, binary_signing_pubkey)
          | tags: tags
        }
      }
    end
  end
end
