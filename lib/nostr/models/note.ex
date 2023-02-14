defmodule Nostr.Models.Note do
  @moduledoc """
  Note struct and manipulation functions
  """

  defstruct [:content]

  alias NostrBasics.Keys.PublicKey
  alias Nostr.Models.Note

  @type t :: %Note{}

  @doc """
  Creates a new nostr note

  ## Examples
      iex> %Nostr.Models.Note{
      ...>   content: "The Times 03/Jan/2009 Chancellor on brink of second bailout for banks"
      ...> }
      ...> |> Nostr.Models.Note.to_event(<<0x5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2::256>>)
      {
        :ok,
        %NostrBasics.Event{
          pubkey: <<0x5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2::256>>,
          kind: 1,
          content: "The Times 03/Jan/2009 Chancellor on brink of second bailout for banks",
          tags: []
        }
      }
  """
  @spec to_event(Note.t(), PublicKey.t()) :: {:ok, Event.t()} | {:error, String.t()}
  def to_event(note, pubkey) do
    Note.Convert.to_event(note, pubkey)
  end
end
