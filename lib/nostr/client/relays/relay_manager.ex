defmodule Nostr.Client.Relays.RelayManager do
  @moduledoc """
  Accepts a list of relays and makes sure they're connected to if available
  """

  use DynamicSupervisor

  alias Nostr.Client.Relays.{RelayManager, RelaySocket}

  def start_link(_options) do
    opts = [strategy: :one_for_one, name: RelayManager]

    DynamicSupervisor.start_link(opts)
  end

  @impl true
  def init(opts) do
    {:ok, opts}
  end

  def add(relay_url) do
    DynamicSupervisor.start_child(RelayManager, {RelaySocket, [relay_url, self()]})
  end

  def active_pids() do
    DynamicSupervisor.which_children(RelayManager)
    |> Enum.map(&get_pid/1)
    |> Enum.filter(&relay_socket_ready?/1)
  end

  defp get_pid({:undefined, pid, :worker, [RelaySocket]}), do: pid

  defp relay_socket_ready?(pid) do
    RelaySocket.ready?(pid)
  end
end
