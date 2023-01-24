defmodule NostrApp.RelaySocketMessageHandler do
  @moduledoc """
  Manage messages received from relaysockets
  """

  require Logger

  @spec handle(atom(), map()) :: :ok

  def handle(:ping, %{url: url}) do
    Logger.info("In test app: got a PING from #{url}")
  end

  def handle(:closing, %{url: url, code: code, reason: reason}) do
    Logger.info("#{url} is closing the connection with code #{code} because: #{inspect(reason)}")
  end

  def handle(:unexpected, %{url: url, frame: frame}) do
    Logger.info("Got an unexpected frame from #{url}: #{inspect(frame)}")
  end

  def handle(:parsing_error, %{url: url, frame: frame}) do
    Logger.info("Got an unexpected frame from #{url}: #{inspect(frame)}")
  end
end
