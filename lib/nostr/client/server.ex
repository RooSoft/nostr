defmodule Nostr.Client.Server do
  use WebSockex
  require Logger

  alias Nostr.Event

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
  def handle_frame({type, msg}, %{client_pid: client_pid} = state) do
    case type do
      :text ->
        {request_id, event} =
          msg
          |> Jason.decode!()
          |> Event.Dispatcher.dispatch()

        send(client_pid, {request_id, event})

      _ ->
        Logger.warn("#{type}: unknown type of frame")
    end

    {:ok, state}
  end

  @impl true
  def handle_frame(x, state) do
    IO.inspect(x, label: "unknown type of frame")

    {:ok, state}
  end
end
