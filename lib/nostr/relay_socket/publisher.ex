defmodule Nostr.RelaySocket.Publisher do
  @moduledoc """
  Sends events to the subscriber's console
  """

  def successful_connection(pid, relay_url) do
    send(pid, {:console, :connected, %{url: relay_url}})
  end

  def unsuccessful_connection(pid, relay_url, message) do
    send(pid, {:console, :cant_connect, %{url: relay_url, message: message}})
  end

  def close(pid, relay_url, code, reason) do
    send(pid, {:console, :close, %{url: relay_url, code: code, reason: reason}})
  end

  def ping(pid, relay_url) do
    send(pid, {:console, :ping, %{url: relay_url}})
  end

  def notice(pid, relay_url, message) do
    send(pid, {:console, :notice, %{url: relay_url, message: message}})
  end

  def unexpected_frame(pid, relay_url, frame) do
    send(pid, {:console, :unexpected, %{url: relay_url, frame: frame}})
  end
end
