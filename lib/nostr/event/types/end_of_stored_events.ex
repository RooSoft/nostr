defmodule Nostr.Event.Types.EndOfStoredEvents do
  @moduledoc """
  Representing an empty event that signals the end of a list of recorded event
  """

  defstruct [:relay_url, :subscription_id]
end
