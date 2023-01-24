defmodule Nostr.RelaySocket.Publisher do
  @moduledoc """
  Sends events to RelaySocket's subscribers
  """

  def successful_connection(pid, relay_url) do
    send(pid, {:relaysocket, :connected, %{url: relay_url}})
  end

  def unsuccessful_connection(pid, relay_url, message) do
    send(pid, {:relaysocket, :cant_connect, %{url: relay_url, message: message}})
  end

  def ping(pid, relay_url) do
    send(pid, {:relaysocket, :ping, %{url: relay_url}})
  end

  def close(pid, relay_url, code, reason) do
    send(pid, {:relaysocket, :close, %{url: relay_url, code: code, reason: reason}})
  end

  def unexpected_frame(pid, relay_url, frame) do
    send(pid, {:relaysocket, :unexpected, %{url: relay_url, frame: frame}})
  end
end
