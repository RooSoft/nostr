defmodule Nostr.Models.Delete.Convert do
  alias NostrBasics.Keys.PublicKey
  alias NostrBasics.Event

  alias Nostr.Models.Delete

  @delete_kind 5

  @doc """
  Convert a delete model to a nostr event

  ## Examples
      iex> %Nostr.Models.Delete{
      ...>   event_ids: ["note1ufw7j6w60xaq04qvwxs2002jt5d8uwe5el7tw2fkfskvnl8f9d7sp9xfah"],
      ...>   note: "these posts were published by accident"
      ...> }
      ...> |> Nostr.Models.Delete.Convert.to_event(<<0x5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2::256>>)
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
  def to_event(
        %Delete{event_ids: event_ids, note: note},
        delete_pubkey
      ) do
    case create_tags(event_ids) do
      {:ok, tags} ->
        {
          :ok,
          %Event{
            Event.create(@delete_kind, note, delete_pubkey)
            | tags: tags
          }
        }

      {:error, message} ->
        {:error, message}
    end
  end

  @spec create_tags(Event.Id.t()) :: {:ok, list()} | {:error, String.t()}
  defp create_tags(event_ids) do
    case to_hex(event_ids) do
      {:ok, hex_ids} -> {:ok, Enum.map(hex_ids, &["e", &1])}
      {:error, message} -> {:error, message}
    end
  end

  defp to_hex(event_ids) when is_list(event_ids) do
    conversion_results =
      event_ids
      |> Enum.map(&to_hex/1)

    case Enum.any?(conversion_results, &result_has_error?/1) do
      true ->
        {:error, "trying to delete, one of the element ids is in an invalid format"}

      false ->
        {:ok, Enum.map(conversion_results, fn {:ok, hex_id} -> hex_id end)}
    end
  end

  defp to_hex(event_id) do
    with {:ok, binary_event_id} <- Event.Id.to_binary(event_id),
         {:ok, _, hex_event_id} <- Event.Id.to_hex(binary_event_id) do
      {:ok, hex_event_id}
    else
      {:error, message} ->
        {:error, message}
    end
  end

  defp result_has_error?({:ok, _}), do: false
  defp result_has_error?({:error, _}), do: true
end
