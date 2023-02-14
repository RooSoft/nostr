defmodule Nostr.Client.Workflows.UpdateProfile do
  @moduledoc """
  A process that's responsible to subscribe and listen to relays so
  it can properly update a user's profile
  """

  use GenServer

  require Logger

  alias NostrBasics.Event
  alias NostrBasics.Event.{Signer, Validator}
  alias NostrBasics.Keys.PublicKey
  alias NostrBasics.Models.Profile

  alias Nostr.Client.Relays.RelaySocket

  def start_link(relay_pids, %Profile{} = new_profile, privkey) do
    GenServer.start(__MODULE__, %{
      relay_pids: relay_pids,
      privkey: privkey,
      new_profile: new_profile
    })
  end

  @impl true
  def init(%{new_profile: new_profile} = state) do
    send(self(), {:update, new_profile})

    {:ok, state}
  end

  @impl true
  def handle_info(
        {:update, new_profile},
        %{privkey: privkey, relay_pids: relay_pids} = state
      ) do
    update_profile(new_profile, privkey, relay_pids)

    {:noreply, state}
  end

  defp update_profile(%Profile{} = new_profile, private_key, relay_pids) do
    with {:ok, pubkey} <- PublicKey.from_private_key(private_key),
         {:ok, profile_event} <- create_profile_event(new_profile, pubkey),
         {:ok, signed_event} <- prepare_and_sign_event(profile_event, private_key) do
      :ok = Validator.validate_event(signed_event)

      send_event(signed_event, relay_pids)

      :ok
    else
      {:error, message} -> {:error, message}
    end
  end

  defp create_profile_event(%Profile{} = profile, pubkey) do
    profile
    |> Profile.to_event(pubkey)
  end

  defp prepare_and_sign_event(event, private_key) do
    %Event{event | created_at: DateTime.utc_now()}
    |> Event.add_id()
    |> Signer.sign_event(private_key)
  end

  defp send_event(validated_event, relay_pids) do
    for relay_pid <- relay_pids do
      RelaySocket.send_event(relay_pid, validated_event)
    end
  end
end
