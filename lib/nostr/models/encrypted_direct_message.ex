defmodule Nostr.Models.EncryptedDirectMessage do
  @moduledoc """
  Encrypted direct message struct and manipulation functions
  """

  defstruct [:content, :remote_pubkey]

  alias NostrBasics.Keys.{PrivateKey}
  alias Nostr.Models.EncryptedDirectMessage

  @type t :: %EncryptedDirectMessage{}

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
      ...> |> Nostr.Models.EncryptedDirectMessage.to_event(<<0x4E22DA43418DD934373CBB38A5AB13059191A2B3A51C5E0B67EB1334656943B8::256>>)
      ...> %NostrBasics.Event{event | content: nil}
      %NostrBasics.Event{
        pubkey: <<0x5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2::256>>,
        kind: 4,
        tags: [
          ["p", "efc83f01c8fb309df2c8866b8c7924cc8b6f0580afdde1d6e16e2b6107c2862c"]
        ]
      }
  """
  @spec to_event(EncryptedDirectMessage.t(), PrivateKey.t()) ::
          {:ok, Event.t()} | {:error, String.t()}
  def to_event(encrypted_direct_message, private_key) do
    EncryptedDirectMessage.Convert.to_event(encrypted_direct_message, private_key)
  end
end
