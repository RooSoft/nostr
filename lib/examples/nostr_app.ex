defmodule NostrApp do
  alias NostrApp.Server

  def start_link(relays, <<_::256>> = private_key) do
    args = %{relays: relays, private_key: private_key}

    GenServer.start_link(Server, args, name: Server)
  end

  def send(note) do
    GenServer.cast(Server, {:send, note})
  end

  def profile(pubkey) do
    GenServer.cast(Server, {:profile, pubkey})
  end

  def contacts(pubkey) do
    GenServer.cast(Server, {:contacts, pubkey})
  end

  def notes(pubkey) do
    GenServer.cast(Server, {:notes, pubkey})
  end

  def reposts(pubkeys) when is_list(pubkeys) do
    GenServer.cast(Server, {:reposts, pubkeys})
  end

  def reactions(pubkeys) when is_list(pubkeys) do
    GenServer.cast(Server, {:reactions, pubkeys})
  end

  def timeline(pubkey) do
    GenServer.cast(Server, {:timeline, pubkey})
  end
end
