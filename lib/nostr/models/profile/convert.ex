defmodule Nostr.Models.Profile.Convert do
  alias NostrBasics.Keys.PublicKey
  alias NostrBasics.Event

  alias Nostr.Models.Profile

  @reaction_kind 0

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
      ...> |> Nostr.Models.Profile.Convert.to_event(<<0x5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2::256>>)
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
  def to_event(%Profile{} = profile, pubkey) do
    case Jason.encode(profile) do
      {:ok, json_profile} ->
        {
          :ok,
          Event.create(@reaction_kind, json_profile, pubkey)
        }

      {:error, message} ->
        {:error, message}
    end
  end
end
