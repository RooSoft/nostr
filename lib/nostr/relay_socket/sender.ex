defmodule Nostr.RelaySocket.Sender do
  @moduledoc """
  Responsible for sending frames through the websocket connection
  """

  require Logger

  alias Nostr.Client.{SendRequest}
  alias Mint.{HTTP, WebSocket}

  @spec send_pong(map(), String.t()) :: {:ok, map()} | {:error, map(), any()}
  def send_pong(state, data) do
    send_frame(state, {:pong, data})
  end

  @spec send_text(map(), String.t()) :: map()
  def send_text(state, data) do
    case send_frame(state, {:text, data}) do
      {:ok, state} ->
        state

      {:error, state, reason} ->
        Logger.error(reason)
        state
    end
  end

  @spec send_subscription_request(map(), atom(), String.t(), pid()) :: map()
  def send_subscription_request(state, atom_subscription_id, json, subscriber) do
    case send_subscription_to_websocket(state, atom_subscription_id, json, subscriber) do
      {:ok, state} ->
        state

      {:error, state, reason} ->
        Logger.error(reason)
        state
    end
  end

  @spec send_close_message(map(), pid()) :: map()
  def send_close_message(state, subscription_id) do
    json_request = SendRequest.close(subscription_id)

    case send_frame(state, {:text, json_request}) do
      {:ok, state} ->
        state
        |> remove_subscription(subscription_id)

      {:error, state, reason} ->
        Logger.error(reason)
        state
    end
  end

  @spec close(map()) :: HTTP.t()
  def close(%{conn: conn} = state) do
    _ = send_frame(state, :close)

    {:ok, conn} = HTTP.close(conn)

    conn
  end

  @spec send_subscription_to_websocket(map(), atom(), String.t(), pid()) ::
          {:ok, map()} | {:error, map(), any()}
  defp send_subscription_to_websocket(state, atom_subscription_id, json, subscriber) do
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
    with {:ok, websocket, data} <- WebSocket.encode(state.websocket, frame),
         state = put_in(state.websocket, websocket),
         {:ok, conn} <- WebSocket.stream_request_body(state.conn, state.request_ref, data) do
      {:ok, put_in(state.conn, conn)}
    else
      {:error, %WebSocket{} = websocket, reason} ->
        {:error, put_in(state.websocket, websocket), reason}

      {:error, conn, reason} ->
        {:error, put_in(state.conn, conn), reason}
    end
  end

  defp add_subscription(state, atom_subscription_id, subscriber) do
    %{state | subscriptions: [{atom_subscription_id, subscriber}] ++ state.subscriptions}
  end

  defp remove_subscription(%{subscriptions: subscriptions} = state, atom_subscription_id) do
    new_subscriptions = subscriptions |> Keyword.delete(atom_subscription_id)

    %{state | subscriptions: new_subscriptions}
  end
end
