defmodule Nostr.Client.Request do
  def author(pub_key, limit \\ 10) do
    [
      "REQ",
      "myreq",
      %{
        authors: [pub_key],
        limit: limit
      }
    ]
    |> Jason.encode!()
  end
end
