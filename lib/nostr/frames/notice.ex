defmodule Nostr.Frames.Notice do
  @moduledoc """
  A relay sending an administrative message to the app's console

  Defined in NIP-01
  """

  defstruct [:message]
end
