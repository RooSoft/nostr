defmodule Nostr.RelaySocket.FrameHandler do
  @moduledoc """
  Websocket frames are first sent here to be decoded and then sent to the frame dispatcher
  """

  require Logger

  def handle_text_frame(frame, subscriptions, conn) do
    with {:ok, data} <- Jason.decode(frame),
         {:ok, item} <- Nostr.Client.FrameDispatcher.dispatch(data) do
      case get_atom_id(item) do
        nil ->
          :ok

        atom_id ->
          case Keyword.get(subscriptions, atom_id) do
            nil ->
              :ok

            subscriber ->
              {_id, event} = item

              send(subscriber, {conn.host, event})
          end
      end
    else
      {:error, _} -> Logger.warning("cannot parse frame: #{frame}")
    end
  end

  defp get_atom_id({id, _}) do
    String.to_atom(id)
  end
end
