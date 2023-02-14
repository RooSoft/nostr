defmodule Nostr.Models.Repost do
  @moduledoc """
  Repost event struct and manipulation functions
  """

  defstruct [:event, :relays]

  alias NostrBasics.Event
  alias NostrBasics.Keys.PublicKey

  alias Nostr.Models.Repost

  @type t :: %Repost{}

  @doc """
  Convert a repost model to a nostr event

  ## Examples
      iex> event = %NostrBasics.Event{
      ...>   id: "012b55abd446d7f4e4abc5b2570ce61c3e289f5683128fd469dd2016401234e4",
      ...>   pubkey: <<0x7f3b464b9ff3623630485060cbda3a7790131c5339a7803bde8feb79a5e1b06a::256>>,
      ...>   created_at: ~U[2023-02-14 00:43:37Z],
      ...>   kind: 1,
      ...>   tags: [
      ...>     ["e", "57d70d162b28c66b152c5c99d0b73490b5362b93baf7746e0715f5221d0e18aa"],
      ...>     ["e", "771eeb8a06fbff0e416a9c27da152d52f594e540dd7b09b4d512d5e488377f73"],
      ...>     ["p", "dbe0605a9c73172bad7523a327b236d55ea4b634e80e78a9013db791f8fd5b2c"],
      ...>     ["p", "a9b9525992a486aa16b3c1d3f9d3604bca08f3c15b712d70711b9aecd8c3dc44"]
      ...>   ],
      ...>   content: "I just zapped you. My first zap!",
      ...>   sig: <<0x4dd5e4718dcc854e57d3ab37b1f2c515f1a13beeeabc1a7c93c338510c26407a86ccd9f38ebcb97389ca875307ac05ee0784dbbe09c1cc000cf707157c723847::512>>
      ...> }
      ...> relays = ["wss://nos.lol"]
      ...> %Nostr.Models.Repost{event: event, relays: relays}
      ...> |> Nostr.Models.Repost.to_event(<<0x5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2::256>>)
      {
        :ok,
        %NostrBasics.Event{
          pubkey: <<0x5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2::256>>,
          kind: 6,
          tags: [
            ["e", "012b55abd446d7f4e4abc5b2570ce61c3e289f5683128fd469dd2016401234e4"],
            ["p", "7f3b464b9ff3623630485060cbda3a7790131c5339a7803bde8feb79a5e1b06a"]
          ],
          content: ~s({"content":"I just zapped you. My first zap!","created_at":1676335417,"id":"012b55abd446d7f4e4abc5b2570ce61c3e289f5683128fd469dd2016401234e4","kind":1,"pubkey":"7f3b464b9ff3623630485060cbda3a7790131c5339a7803bde8feb79a5e1b06a","relays":["wss://nos.lol"],"sig":"4dd5e4718dcc854e57d3ab37b1f2c515f1a13beeeabc1a7c93c338510c26407a86ccd9f38ebcb97389ca875307ac05ee0784dbbe09c1cc000cf707157c723847","tags":[["e","57d70d162b28c66b152c5c99d0b73490b5362b93baf7746e0715f5221d0e18aa"],["e","771eeb8a06fbff0e416a9c27da152d52f594e540dd7b09b4d512d5e488377f73"],["p","dbe0605a9c73172bad7523a327b236d55ea4b634e80e78a9013db791f8fd5b2c"],["p","a9b9525992a486aa16b3c1d3f9d3604bca08f3c15b712d70711b9aecd8c3dc44"]]})
        }
      }
  """
  @spec to_event(Repost.t(), PublicKey.t()) :: {:ok, Event.t()} | {:error, String.t()}
  def to_event(repost, pubkey) do
    Repost.Convert.to_event(repost, pubkey)
  end
end
