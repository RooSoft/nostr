defmodule Nostr.Client.SendRequest do
  def event(signed_event) do
    [
      "EVENT",
      signed_event
    ]
    |> Jason.encode!()
  end
end
