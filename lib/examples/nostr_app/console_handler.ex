defmodule NostrApp.ConsoleHandler do
  @moduledoc """
  Manage messages received from relaysockets
  """

  require Logger

  @spec handle(atom(), map()) :: :ok

  def handle(:connected, %{url: url}) do
    Logger.info("HTTP connection to #{url}")
  end

  def handle(:websockets_ready, %{url: url}) do
    Logger.info("Websockets activated for #{url}")
  end

  def handle(:cant_connect, %{url: url, message: message}) do
    Logger.warning("Can't connect to #{url} because #{message}")
  end

  def handle(:ping, %{url: url}) do
    Logger.info("In test app: got a PING from #{url}")
  end

  def handle(:close, %{url: url, code: code, reason: reason}) do
    Logger.info("#{url} is closing the connection with code #{code} because: #{inspect(reason)}")
  end

  def handle(:not_ready, %{url: url, reason: reason}) do
    Logger.info("#{url} is not ready: #{reason}")
  end

  def handle(:unexpected, %{url: url, frame: frame}) do
    Logger.warning("Got an unexpected frame from #{url}: #{inspect(frame)}")
  end

  def handle(:parsing_error, %{url: url, frame: frame}) do
    Logger.warning("Got an parsing error from #{url}: #{inspect(frame)}")
  end

  def handle(:notice, %{url: url, message: message}) do
    Logger.info("NOTICE from #{url}: #{message}")
  end

  def handle(:transport_error, %{url: url, message: message}) do
    Logger.warning("transport error from #{url}: #{message}")
  end

  def handle(:unknown_relay_message, %{url: url, message: message}) do
    Logger.warning("unknown relay message from #{url}: #{message}")
  end

  def handle(:malformed_json_relay_message, %{url: url, message: message}) do
    Logger.warning("malformed JSON relay message from #{url}: #{message}")
  end

  def handle(:ok, %{event_id: event_id, message: _message, success?: success?, url: url}) do
    Logger.info("#{url} sent #{event_id}: #{success?}")
  end

  def handle(unknown_atom, data) do
    Logger.warning("got a #{unknown_atom}: #{inspect(data)}")
  end
end
