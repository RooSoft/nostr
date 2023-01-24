defmodule Nostr.RelaySocket.FrameHandler do
  @moduledoc """
  Websocket frames are first sent here to be decoded and then sent to the frame dispatcher
  """

  alias Nostr.Frames.Notice

  @spec handle_text_frame(list(), list(), map(), pid()) :: :ok
  def handle_text_frame(frame, subscriptions, relay_url, owner_pid) do
    with {:ok, data} <- Jason.decode(frame),
         {:ok, item} <- Nostr.Client.FrameDispatcher.dispatch(data) do
      case get_atom_id(item) do
        nil ->
          %Notice{message: message} = get_event(item)
          send(owner_pid, {:relaysocket, :notice, %{url: relay_url, message: message}})

        atom_id ->
          case Keyword.get(subscriptions, atom_id) do
            nil ->
              :ok

            subscriber ->
              {_id, event} = item

              send(subscriber, {relay_url, event})
          end
      end

      :ok
    else
      {:error, _} ->
        send(owner_pid, {:relaysocket, :parsing_error, %{url: relay_url, frame: frame}})
        :ok
    end
  end

  defp get_atom_id({nil, _}), do: nil
  defp get_atom_id({id, _}), do: String.to_atom(id)

  defp get_event({_, event}), do: event
end
