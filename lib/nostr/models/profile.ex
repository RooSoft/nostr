defmodule Nostr.Models.Profile do
  @moduledoc """
  Represents a user's profile
  """

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

  @doc """
  Creates a new nostr profile

  ## Examples
      iex> %Nostr.Models.Profile{
      ...>   about: "some user description",
      ...>   banner: "https://image.com/satoshi_banner",
      ...>   display_name: "satoshi nakamoto",
      ...>   lud16: "satoshi@nakamoto.jp",
      ...>   name: "satoshi nakamoto",
      ...>   nip05: "_@nakamoto.jp",
      ...>   picture: "https://image.com/satoshi_avatar",
      ...>   website: "https://bitcoin.org"
      ...> }
      ...> |> Nostr.Models.Profile.to_event(<<0x5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2::256>>)
      {
        :ok,
        %NostrBasics.Event{
          pubkey: <<0x5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2::256>>,
          kind: 0,
          tags: [],
          content: ~s({"about":"some user description","banner":"https://image.com/satoshi_banner","display_name":"satoshi nakamoto","lud16":"satoshi@nakamoto.jp","name":"satoshi nakamoto","nip05":"_@nakamoto.jp","picture":"https://image.com/satoshi_avatar","website":"https://bitcoin.org"})
        }
      }
  """
  @spec to_event(Profile.t(), PublicKey.t()) :: {:ok, Event.t()} | {:error, String.t()}
  def to_event(profile, pubkey) do
    Profile.Convert.to_event(profile, pubkey)
  end
end
