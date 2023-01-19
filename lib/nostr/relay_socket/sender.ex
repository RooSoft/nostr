defmodule Nostr.RelaySocket.Sender do
  @moduledoc """
  Responsible for sending frames through the websocket connection
  """

  require Logger

  @spec send_pong(map(), String.t()) :: {:ok, map()} | {:error, map(), any()}
  def send_pong(state, data) do
    send_frame(state, {:pong, data})
  end

  @spec send_subscription_request(map(), atom(), String.t(), pid()) :: map()
  def send_subscription_request(state, atom_subscription_id, json, subscriber) do
    case send_to_websocket(state, atom_subscription_id, json, subscriber) do
      {:ok, state} ->
        state

      {:error, state, reason} ->
        Logger.error(reason)
        state
    end
  end

  @spec close(map()) :: Mint.HTTP.t()
  def close(%{conn: conn} = state) do
    _ = send_frame(state, :close)

    {:ok, conn} = Mint.HTTP.close(conn)

    conn
  end

  @spec send_to_websocket(map(), atom(), String.t(), pid()) ::
          {:ok, map()} | {:error, map(), any()}
  defp send_to_websocket(state, atom_subscription_id, json, subscriber) do
    case send_frame(state, {:text, json}) do
      {:ok, state} ->
        {
          :ok,
          state
          |> add_subscription(atom_subscription_id, subscriber)
        }

      {:error, state, message} ->
        {:error, state, message}
    end
  end

  @spec send_frame(map(), any()) :: {:ok, map()} | {:error, map(), any()}
  defp send_frame(state, frame) do
    with {:ok, websocket, data} <- Mint.WebSocket.encode(state.websocket, frame),
         state = put_in(state.websocket, websocket),
         {:ok, conn} <- Mint.WebSocket.stream_request_body(state.conn, state.request_ref, data) do
      {:ok, put_in(state.conn, conn)}
    else
      {:error, %Mint.WebSocket{} = websocket, reason} ->
        {:error, put_in(state.websocket, websocket), reason}

      {:error, conn, reason} ->
        {:error, put_in(state.conn, conn), reason}
    end
  end

  defp add_subscription(state, atom_subscription_id, subscriber) do
    %{state | subscriptions: [{atom_subscription_id, subscriber}] ++ state.subscriptions}
  end
end
