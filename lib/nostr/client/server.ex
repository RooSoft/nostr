defmodule Nostr.Client.Server do
  use WebSockex
  require Logger

  alias Nostr.Client.{Event, Request}

  def handle_connect(_conn, state) do
    Logger.warning("Connected to relay...")

    request =
      Request.author("efc83f01c8fb309df2c8866b8c7924cc8b6f0580afdde1d6e16e2b6107c2862c")
      |> IO.inspect(label: "sending")

    WebSockex.cast(self(), {:send_message, request})

    {:ok, state}
  end

  def handle_cast({:send_message, subscription_json}, state) do
    Logger.info("subscribing messages...")
    IO.inspect(subscription_json, label: "from handle_cast")

    {:reply, {:text, subscription_json}, state}
  end

  def handle_frame({type, msg}, state) do
    case type do
      :text ->
        msg
        |> Jason.decode!()
        |> IO.inspect(label: "the message")
        |> Event.dispatch()

      _ ->
        Logger.warn("#{type}: unknown type of frame")
    end

    {:ok, state}
  end
end
