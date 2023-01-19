defmodule Nostr.RelaySocket.Publisher do
  @moduledoc """
  Sends events to RelaySocket's subscribers
  """

  def successful_connection(pid, relay_url) do
    send(pid, {:relay_socket, :connected, relay_url})
  end

  def unsuccessful_connection(pid, relay_url, message) do
    send(pid, {:relay_socket, :cant_connect, relay_url, message})
  end
end
