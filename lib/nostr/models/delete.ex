defmodule Nostr.Models.Delete do
  @moduledoc """
  Delete event struct and manipulation functions
  """

  defstruct [:note, event_ids: []]

  alias NostrBasics.Keys.PublicKey
  alias Nostr.Models.Delete

  @type t :: %Delete{}

  @doc """
  Convert a delete model to a nostr event

  ## Examples
      iex> %Nostr.Models.Delete{
      ...>   event_ids: ["note1ufw7j6w60xaq04qvwxs2002jt5d8uwe5el7tw2fkfskvnl8f9d7sp9xfah"],
      ...>   note: "these posts were published by accident"
      ...> }
      ...> |> Nostr.Models.Delete.to_event(<<0x5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2::256>>)
      {
        :ok,
        %NostrBasics.Event{
          pubkey: <<0x5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2::256>>,
          kind: 5,
          tags: [
            ["e", "e25de969da79ba07d40c71a0a7bd525d1a7e3b34cffcb729364c2cc9fce92b7d"],
          ],
          content: "these posts were published by accident"
        }
      }
  """
  @spec to_event(Delete.t(), PublicKey.t()) :: {:ok, Event.t()} | {:error, String.t()}
  def to_event(delete_event, pubkey) do
    Delete.Convert.to_event(delete_event, pubkey)
  end
end
