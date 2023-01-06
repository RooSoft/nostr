defmodule Nostr.RelaySocket.FrameHandler do
  require Logger

  def handle_text_frame(frame, subscriptions) do
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

              send(subscriber, event)
          end
      end
    else
      {:error, _} -> Logger.warning("cannot parse frame: #{frame}")
    end
  end

  defp get_atom_id({id, _}) do
    String.to_atom(id)
  end

  defp get_atom_id(_) do
    nil
  end
end
