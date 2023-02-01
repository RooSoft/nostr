defmodule Nostr.Client.Relays.RelaySocket.Connector do
  @moduledoc """
  Websocket connection initialization

  Based on https://hexdocs.pm/mint_web_socket/Mint.WebSocket.html

  Once the upgrade request is done, response will go through
  MessageDispatcher.dispatch/2 and the connection process will
  continue from that point on.
  """
  alias Mint.{HTTP, Types, WebSocket}

  @spec connect(String.t()) :: {:ok, HTTP.t(), Types.request_ref()} | {:error, Types.error()}
  def connect(relay_url) do
    uri = URI.parse(relay_url)

    http_scheme =
      case uri.scheme do
        "ws" -> :http
        "wss" -> :https
      end

    ws_scheme =
      case uri.scheme do
        "ws" -> :ws
        "wss" -> :wss
      end

    path = uri.path

    with {:ok, conn} <- HTTP.connect(http_scheme, uri.host, uri.port, protocols: [:http1]),
         {:ok, conn, ref} <- WebSocket.upgrade(ws_scheme, conn, path, []) do
      {:ok, conn, ref}
    else
      {:error, %Mint.TransportError{reason: :nxdomain}} ->
        message = "domain doesn't exist"
        {:error, message}

      {:error, reason} ->
        {:error, reason}

      {:error, _conn, reason} ->
        {:error, reason}
    end
  end
end
