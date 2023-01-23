defmodule NostrApp.RelaySocketMessageHandler do
  @moduledoc """
  Manage messages received from relaysockets
  """

  require Logger

  @spec handle(atom(), map()) :: :ok

  def handle(:ping, %{url: url}) do
    Logger.info("In test app: got a PING from #{url}")
  end

  def handle(:closing, %{url: url, reason: reason}) do
    Logger.info("#{url} is closing the connection because: #{reason}")
  end

  def handle(:unexpected, %{url: url, frame: frame}) do
    Logger.info("Got an unexpected frame from #{url}: #{inspect(frame)}")
  end
end
