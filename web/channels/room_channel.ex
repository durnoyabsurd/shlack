defmodule Shlack.RoomChannel do
  use Phoenix.Channel
  require Logger

  alias Shlack.Repo
  alias Shlack.Channel
  alias Shlack.User
  alias Shlack.UserChannel
  alias Shlack.Message

  def join("rooms:" <> name, _, socket) do
    channel = find_or_create_channel(name, socket)
    user_channel = find_or_create_user_channel(channel, socket)

    if user_channel do
      send(self, :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "join failed"}}
    end
  end

  def handle_info(:after_join, socket) do
    "rooms:" <> channel = socket.topic

    broadcast! socket, "user_joined", %{
      user: socket.assigns.user.name,
      channel: channel}

    {:noreply, socket}
  end

  def handle_in("send_message", %{"text" => text, "channel" => channel_name}, socket) do
    user = socket.assigns.user
    channel = find_channel(channel_name)
    message = Repo.insert(%Message{channel: channel, user: user, text: text})

    if message do
      broadcast! socket, "message_sent", %{
        channel: channel.name,
        user: user.name,
        text: text}

      {:noreply, socket}
    else
      {:error, %{reason: "message save failed"}}
    end
  end

  defp find_or_create_channel(name, socket) do
    find_channel(name) || create_channel(name, socket)
  end

  defp find_channel(name) do
    Repo.get_by(Channel, name: name)
  end

  defp create_channel(name, socket) do
    channel = Repo.insert(%Channel{name: name})

    if channel do
      broadcast! socket, "channel_created", %{name: name}
    end

    channel
  end

  defp find_or_create_user_channel(channel, socket) do
    user = socket.assigns.user
    Repo.get_by(UserChannel, user_id: user.id, channel_id: channel.id) ||
      Repo.insert!(%UserChannel{user_id: user.id, channel_id: channel.id})
  end
end
