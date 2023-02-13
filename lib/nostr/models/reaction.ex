defmodule Nostr.Models.Reaction do
  @moduledoc """
  Reaction struct and manipulation functions
  """

  defstruct [:event_id, :event_pubkey, content: "+"]

  alias NostrBasics.Keys.PublicKey
  alias Nostr.Models.Reaction

  @type t :: %Reaction{}

  @doc """
      iex> %Nostr.Models.Reaction{
      ...>   event_id: "note1ufw7j6w60xaq04qvwxs2002jt5d8uwe5el7tw2fkfskvnl8f9d7sp9xfah",
      ...>   event_pubkey: "npub1dergggklka99wwrs92yz8wdjs952h2ux2ha2ed598ngwu9w7a6fsh9xzpc"
      ...> }
      ...> |> Nostr.Models.Reaction.to_event(<<0x5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2::256>>)
      {
        :ok,
        %NostrBasics.Event{
          pubkey: <<0x5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2::256>>,
          kind: 7,
          tags: [
            ["e", "e25de969da79ba07d40c71a0a7bd525d1a7e3b34cffcb729364c2cc9fce92b7d"],
            ["p", "6e468422dfb74a5738702a8823b9b28168abab8655faacb6853cd0ee15deee93"]
          ],
          content: "+"
        }
      }
  """
  @spec to_event(Reaction.t(), PublicKey.t()) :: {:ok, Event.t()} | {:error, String.t()}
  def to_event(reaction, pubkey) do
    Reaction.Convert.to_event(reaction, pubkey)
  end
end
