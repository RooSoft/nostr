defmodule Nostr.Event.Dispatcher do
  @moduledoc """
  Receive raw nostr protocol events and send them to the right module so it can
  be parsed in the appropriate way and sent back in a usable way
  """

  require Logger

  alias Nostr.Event.Types.{
    MetadataEvent,
    TextEvent,
    ContactsEvent,
    EncryptedDirectMessageEvent,
    RepostEvent,
    ReactionEvent
  }

  @doc """
  Dispatch to the right event type depending on content received

  ## Examples
      iex> %{
      ...>   "content" => "aren't you entertained?",
      ...>   "created_at" => 1_672_082_699,
      ...>   "id" => "e02903e546a84d54772121f4bbbe213f171103a3c3a121b5531098dafdaba725",
      ...>   "kind" => 1,
      ...>   "pubkey" => "5ab9f2efb1fda6bc32696f6f3fd715e156346175b93b6382099d23627693c3f2",
      ...>   "sig" =>
      ...>     "8d3b6dc22f3a94e1491ebb6997ff220156c89826e925e383430d0e488e80f4b5aaa03d04f75a3dafd80a97d42a7546c048720b9861cf0df776da824de716f5a6",
      ...>   "tags" => []
      ...> }
      ...>  |> Nostr.Event.Dispatcher.dispatch
      {
        :ok,
        %Nostr.Event.Types.TextEvent{
          event: %Nostr.Event{
            id: "e02903e546a84d54772121f4bbbe213f171103a3c3a121b5531098dafdaba725",
            pubkey: <<0x5AB9F2EFB1FDA6BC32696F6F3FD715E156346175B93B6382099D23627693C3F2::256>>,
            created_at: ~U[2022-12-26 19:24:59Z],
            kind: 1,
            tags: [],
            content: "aren't you entertained?",
            sig:
              <<0x8D3B6DC22F3A94E1491EBB6997FF220156C89826E925E383430D0E488E80F4B5AAA03D04F75A3DAFD80A97D42A7546C048720B9861CF0DF776DA824DE716F5A6::512>>
          }
        }
      }
  """
  def dispatch(%{"kind" => 0} = content) do
    MetadataEvent.parse(content)
  end

  def dispatch(%{"kind" => 1} = content) do
    TextEvent.parse(content)
  end

  def dispatch(%{"kind" => 2} = content) do
    Logger.info("2- recommend relay: #{inspect(content)}")

    {:ok, :recommend_relay_event}
  end

  def dispatch(%{"kind" => 3} = content) do
    ContactsEvent.parse(content)
  end

  def dispatch(%{"kind" => 4} = content) do
    EncryptedDirectMessageEvent.parse(content)
  end

  def dispatch(%{"kind" => 5} = content) do
    Logger.info("5- event deletion: #{inspect(content)}")

    {:ok, :event_deletion_event}
  end

  def dispatch(%{"kind" => 6} = content) do
    RepostEvent.parse(content)
  end

  def dispatch(%{"kind" => 7} = content) do
    ReactionEvent.parse(content)
  end

  def dispatch(%{"kind" => 40} = content) do
    Logger.info("40- channel creation: #{inspect(content)}")

    {:ok, :channel_creation_event}
  end

  def dispatch(%{"kind" => 41} = content) do
    Logger.info("41- channel metadata: #{inspect(content)}")

    {:ok, :channel_metadata_event}
  end

  def dispatch(%{"kind" => 42} = content) do
    Logger.info("42- channel message: #{inspect(content)}")

    {:ok, :channel_message_event}
  end

  def dispatch(%{"kind" => 43} = content) do
    Logger.info("43- channel hide message: #{inspect(content)}")

    {:ok, :channel_hide_message_event}
  end

  def dispatch(%{"kind" => 44} = content) do
    Logger.info("44- channel mute user: #{inspect(content)}")

    {:ok, :channel_mute_user_event}
  end

  def dispatch(%{"kind" => 45} = content) do
    Logger.info("45- public chat reserved: #{inspect(content)}")

    {:ok, :public_chat_reserved_event_45}
  end

  def dispatch(%{"kind" => 46} = content) do
    Logger.info("46- public chat reserved: #{inspect(content)}")

    {:ok, :public_chat_reserved_event_46}
  end

  def dispatch(%{"kind" => 47} = content) do
    Logger.info("47- public chat reserved: #{inspect(content)}")

    {:ok, :public_chat_reserved_event_47}
  end

  def dispatch(%{"kind" => 48} = content) do
    Logger.info("48- public chat reserved: #{inspect(content)}")

    {:ok, :public_chat_reserved_event_48}
  end

  def dispatch(%{"kind" => 49} = content) do
    Logger.info("49- public chat reserved: #{inspect(content)}")

    {:ok, :public_chat_reserved_event_49}
  end

  def dispatch(%{"kind" => kind} = content) do
    Logger.info("#{kind}- unknown event type: #{inspect(content)}")

    {:error, :unknown_event_type}
  end

  def dispatch(contents) do
    Logger.warning("malformed event: #{contents}")

    {:error, :malformed_event}
  end
end
