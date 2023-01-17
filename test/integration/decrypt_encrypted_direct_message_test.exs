defmodule Nostr.Integration.DecryptEncryptedDirectMessageTest do
  use ExUnit.Case, async: true

  alias Nostr.Crypto.AES256CBC

  @remote_public_key <<0xEFC83F01C8FB309DF2C8866B8C7924CC8B6F0580AFDDE1D6E16E2B6107C2862C::256>>
  @local_private_key <<0x4E22DA43418DD934373CBB38A5AB13059191A2B3A51C5E0B67EB1334656943B8::256>>
  @remote_encrypted_message "sWLtVbabr8fzIugnOXo4og==?iv=nxF/xVqbC4JdMRUEC0Jfyg=="
  @original_message "test"

  test "decrypt an encrypted direct message's content" do
    {:ok, message} =
      AES256CBC.decrypt(@remote_encrypted_message, @local_private_key, @remote_public_key)

    assert @original_message == message
  end
end
