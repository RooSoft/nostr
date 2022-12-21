defmodule NostrTest do
  use ExUnit.Case
  doctest Nostr

  test "greets the world" do
    assert Nostr.hello() == :world
  end
end
