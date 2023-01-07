defmodule Nostr.Client.SendRequest do
  def event(signed_event) do
    ["EVENT", signed_event]
    |> Jason.encode!()
  end

  def close(subscription_id) do
    ["CLOSE", subscription_id]
    |> Jason.encode!()
  end
end
