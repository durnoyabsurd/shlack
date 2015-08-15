defmodule Shlack.RoomChannel do
  use Phoenix.Channel
  require Logger

  alias Shlack.Repo
  alias Shlack.Channel
  alias Shlack.User
  alias Shlack.Message

  def join("rooms:" <> _, _, socket) do
    send(self, :after_join)
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    broadcast! socket, "user_joined", %{user: socket.assigns.user.name}
    {:noreply, socket}
  end

  def handle_in("get_channels", _, socket) do
    channels = Repo.all(Channel) |> Enum.map &(%{name: &1.name})
    push socket, "channels", %{channels: channels}
    {:noreply, socket}
  end

  def handle_in("get_users", _, socket) do
    users = Repo.all(User) |> Enum.map &(%{name: &1.name})
    push socket, "users", %{users: users}
    {:noreply, socket}
  end

  def handle_in("send_message", %{"text" => text, "channel" => channel_name}, socket) do
    user = socket.assigns.user
    channel = Repo.get_by(Channel, name: channel_name)

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
    Repo.get_by(Channel, name: name) || create_channel(name, socket)
  end

  defp create_channel(name, socket) do
    channel = Repo.insert(%Channel{name: name})

    if channel do
      broadcast! socket, "channel_created", %{name: name}
    end

    channel
  end
end
