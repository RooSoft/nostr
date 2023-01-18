defmodule Nostr.Models.Profile do
  defstruct [:about, :banner, :display_name, :lud16, :name, :nip05, :picture, :website]

  alias Nostr.Models.Profile

  @type t :: %Profile{}

  # This thing is needed so that the Jason library knows how to serialize the events
  defimpl Jason.Encoder do
    def encode(
          %Profile{} = profile,
          opts
        ) do
      profile
      |> Map.from_struct()
      |> Enum.filter(&(&1 != nil))
      |> Enum.into(%{})
      |> Jason.Encode.map(opts)
    end
  end
end
