defmodule Nostr.Client.Server do
  use WebSockex
  require Logger

  alias Nostr.Event
  alias Nostr.Event.{Request}

  def handle_connect(_conn, state) do
    Logger.info("Connected to relay...")

    request =
      Request.author("efc83f01c8fb309df2c8866b8c7924cc8b6f0580afdde1d6e16e2b6107c2862c", 100)

    WebSockex.cast(self(), {:send_message, request})

    {:ok, state}
  end

  def handle_cast({:send_message, subscription_json}, state) do
    Logger.info("Subscribing messages...")

    {:reply, {:text, subscription_json}, state}
  end

  def handle_frame({type, msg}, %{client_pid: client_pid} = state) do
    case type do
      :text ->
        event =
          msg
          |> Jason.decode!()
          |> Event.dispatch()

        send(client_pid, event)

      _ ->
        Logger.warn("#{type}: unknown type of frame")
    end

    {:ok, state}
  end
end
