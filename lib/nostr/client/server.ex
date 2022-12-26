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
    IO.puts("SEND MESSAGE HAS BEEN CALLED... WILL likely CRASH BELOW")
    IO.inspect(message)
    {:reply, {:text, message}, state}
  end

  @impl true
  def handle_frame({type, msg}, %{client_pid: client_pid} = state) do
    IO.inspect(type, label: "TYPE")
    IO.inspect(msg, label: "MSG")

    case type do
      :text ->
        {request_id, event} =
          msg
          |> Jason.decode!()
          |> Event.dispatch()

        send(client_pid, {request_id, event})

      _ ->
        Logger.warn("#{type}: unknown type of frame")
    end

    {:ok, state}
  end

  @impl true
  def handle_frame(x, state) do
    IO.inspect(x, label: "XXXXXXXX")

    {:ok, state}
  end
end
