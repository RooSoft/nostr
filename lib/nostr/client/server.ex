defmodule Nostr.Client.Server do
  use WebSockex

  require Logger

  alias Nostr.Client.Server.FrameDispatcher

  @impl true
  def handle_connect(_conn, %{client_pid: client_pid} = state) do
    Logger.info("Connected to relay...")

    send(client_pid, :connected)

    {:ok, state}
  end

  @impl true
  def handle_cast({:send_message, message}, state) do
    {:reply, {:text, message}, state}
  end

  @impl true
  def handle_frame({frame_type, frame}, %{client_pid: client_pid} = state) do
    case frame_type do
      :text ->
        handle_text_frame(frame, client_pid)

      _ ->
        Logger.warning("#{frame_type}: unknown frame type")
    end

    {:ok, state}
  end

  @impl true
  def handle_frame(x, state) do
    Logger.warning(x, label: "unknown frame type")

    {:ok, state}
  end

  defp handle_text_frame(frame, client_pid) do
    with {:ok, data} <- Jason.decode(frame),
         {:ok, item} <- FrameDispatcher.dispatch(data) do
      send(client_pid, item)
    else
      {:error, _} -> Logger.warning("cannot parse frame: #{frame}")
    end
  end
end
