defmodule Nostr.Client.Relays.RelaySocket.FrameHandler do
  @moduledoc """
  Websocket frames are first sent here to be decoded and then sent to the frame dispatcher
  """

  alias NostrBasics.RelayMessage

  @spec handle_text_frame(list(), list(), map(), pid()) :: :ok
  def handle_text_frame(frame, subscriptions, relay_url, owner_pid) do
    RelayMessage.parse(frame)
    |> handle_message(subscriptions, relay_url, owner_pid)
  end

  defp handle_message({:event, subscription_id, event}, subscriptions, relay_url, _owner_pid) do
    case Keyword.get(subscriptions, String.to_atom(subscription_id)) do
      nil -> {relay_url, event}
      subscriber -> send(subscriber, {relay_url, subscription_id, event})
    end
  end

  defp handle_message({:notice, message}, _subscriptions, relay_url, owner_pid) do
    send(owner_pid, {:console, :notice, %{url: relay_url, message: message}})
  end

  defp handle_message(
         {:end_of_stored_events, subscription_id},
         subscriptions,
         relay_url,
         _owner_pid
       ) do
    message = {:end_of_stored_events, relay_url, subscription_id}

    case Keyword.get(subscriptions, String.to_atom(subscription_id)) do
      nil -> message
      subscriber -> send(subscriber, message)
    end
  end

  defp handle_message({:ok, event_id, success?, message}, _subscriptions, relay_url, owner_pid) do
    info = %{url: relay_url, event_id: event_id, success?: success?, message: message}
    send(owner_pid, {:console, :ok, info})
  end

  defp handle_message({:unknown, message}, _subscriptions, relay_url, owner_pid) do
    send(owner_pid, {:console, :unknown_relay_message, url: relay_url, message: message})
  end

  defp handle_message({:json_error, message}, _subscriptions, relay_url, owner_pid) do
    send(owner_pid, {:console, :malformed_json_relay_message, url: relay_url, message: message})
  end
end
