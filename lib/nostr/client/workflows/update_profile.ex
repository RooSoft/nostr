defmodule Nostr.Client.Workflows.UpdateProfile do
  @moduledoc """
  A process that's responsible to subscribe and listen to relays so
  it can properly update a user's profile
  """

  use GenServer

  require Logger

  alias Nostr.Client.RelaySocket
  alias Nostr.Models.Profile
  alias Nostr.Event.{Signer, Validator}
  alias Nostr.Event.Types.{MetadataEvent}

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

    {
      :ok,
      state
      |> Map.put(:treated, false)
    }
  end

  @impl true
  def handle_info(
        {:update, new_profile},
        %{treated: false, privkey: privkey, relay_pids: relay_pids} = state
      ) do
    update_profile(new_profile, privkey, relay_pids)

    {
      :noreply,
      state
      |> Map.put(:treated, true)
    }
  end

  defp update_profile(%Profile{} = new_profile, privkey, relay_pids) do
    pubkey = Nostr.Keys.PublicKey.from_private_key!(privkey)

    with {:ok, event} <- MetadataEvent.create_event(new_profile, pubkey),
         {:ok, signed_event} <- Signer.sign_event(event, privkey) do
      Validator.validate_event(signed_event)
      send_event(signed_event, relay_pids)
    else
      {:error, message} ->
        Logger.warning(message)
    end
  end

  defp send_event(validated_event, relay_pids) do
    for relay_pid <- relay_pids do
      RelaySocket.send_event(relay_pid, validated_event)
    end
  end
end
