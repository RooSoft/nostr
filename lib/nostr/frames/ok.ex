defmodule Nostr.Frames.Ok do
  @moduledoc """
  A relay telling the app that a command has been successfully executed

  Defined in NIP-20
  """

  defstruct [:persisted?, :reason]
end
