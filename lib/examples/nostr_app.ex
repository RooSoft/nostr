defmodule NostrApp do
  alias NostrApp.Server

  alias Nostr.Models.Profile

  def start_link(relays, <<_::256>> = private_key) do
    args = %{relays: relays, private_key: private_key}

    GenServer.start_link(Server, args, name: Server)
  end

  ### NIP-01
  def profile(pubkey \\ nil) do
    GenServer.cast(Server, {:profile, pubkey})
  end

  ### NIP-01
  def update_profile(%Profile{} = profile) do
    GenServer.cast(Server, {:update_profile, profile})
  end

  ### NIP-01
  def note(note_id) do
    GenServer.cast(Server, {:note, note_id})
  end

  ### NIP-01
  def notes(pubkey) do
    GenServer.cast(Server, {:notes, pubkey})
  end

  ### NIP-01
  def send_note(note) do
    GenServer.cast(Server, {:send_note, note})
  end

  ### NIP-02
  def contacts(pubkey) do
    GenServer.cast(Server, {:contacts, pubkey})
  end

  ### NIP-02
  def follow(pubkey) do
    GenServer.cast(Server, {:follow, pubkey})
  end

  ### NIP-02
  def unfollow(pubkey) do
    GenServer.cast(Server, {:unfollow, pubkey})
  end

  ### NIP-09
  def deletions(pubkeys) when is_list(pubkeys) do
    GenServer.cast(Server, {:deletions, pubkeys})
  end

  ### NIP-18
  def reposts() do
    GenServer.cast(Server, {:reposts})
  end

  ### NIP-18
  def reposts(pubkeys) when is_list(pubkeys) do
    GenServer.cast(Server, {:reposts, pubkeys})
  end

  ### NIP-25
  def react(note_id) do
    GenServer.cast(Server, {:react, note_id})
  end

  ### NIP-25
  def reactions(pubkeys) when is_list(pubkeys) do
    GenServer.cast(Server, {:reactions, pubkeys})
  end

  ### Combination of multiple NIPs
  def timeline(pubkey) do
    GenServer.cast(Server, {:timeline, pubkey})
  end
end
