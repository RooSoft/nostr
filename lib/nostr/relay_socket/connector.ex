defmodule Nostr.RelaySocket.Connector do
  @moduledoc """
  All things related to websocket connection with relays
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

    path = "/"

    with {:ok, conn} <-
           HTTP.connect(http_scheme, uri.host, uri.port, protocols: [:http1]),
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
