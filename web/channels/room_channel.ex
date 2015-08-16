defmodule Shlack.RoomChannel do
  use Phoenix.Channel
  require Logger
  require Enum
  require Ecto.Adapters.SQL
  require Ecto.DateTime

  alias Shlack.Repo
  alias Shlack.Channel
  alias Shlack.User
  alias Shlack.Message

  def join("rooms:" <> _, _, socket) do
    send(self, :after_join)
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    user = socket.assigns.user

    broadcast! socket, "user_online", %{user: %{name: user.name, online: user.online}}

    channels = Repo.all(Channel) |> Enum.map &(%{name: &1.name})
    push socket, "channels", %{channels: channels}

    users = Repo.all(User) |> Enum.map &(%{name: &1.name, online: &1.online})
    push socket, "users", %{users: users}

    push socket, "messages", %{messages: messages_log}
    {:noreply, socket}
  end

  def terminate(_, socket) do
    user = %{socket.assigns.user | online: false}
    Repo.update!(user)
    broadcast! socket, "user_offline", %{user: %{name: user.name, online: user.online}}
    {:ok, socket}
  end

  def handle_in("ping", _, socket) do
    {:reply, :pong, socket}
  end

  def handle_in("send_message", %{"text" => text, "channel" => channel_name}, socket) do
    user = socket.assigns.user
    channel = Repo.get_by(Channel, name: channel_name)

    message = Repo.insert(%Message{
      channel_id: channel.id,
      user_id: user.id,
      text: text})

    case message do
      {:ok, message} ->
        broadcast! socket, "incoming_message", %{
          channel: channel.name,
          user: user.name,
          text: text,
          inserted_at: message.inserted_at}
        {:reply, :ok, socket}
      {:error, _} ->
        {:reply, {:error, %{reason: "message save failed"}}, socket}
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

  defp messages_log do
    # Last 100 messages for each channel
    query = ~s"""
      SELECT *
      FROM (
        SELECT
          ROW_NUMBER() OVER (
            PARTITION BY m.channel_id
            ORDER BY m.inserted_at DESC) AS r,
          c.name AS channel,
          u.name AS user,
          m.text,
          m.inserted_at
        FROM messages AS m
        INNER JOIN channels AS c
          ON c.id = m.channel_id
        INNER JOIN users AS u
          ON u.id = m.user_id) AS x
      WHERE x.r <= 100
      ORDER BY x.inserted_at
    """

    %{rows: data} = Ecto.Adapters.SQL.query(Repo, query, [])

    Enum.map data, fn(row) ->
      {:ok, inserted_at} = Enum.at(row, 4) |> Ecto.DateTime.cast

      %{channel: Enum.at(row, 1),
        user: Enum.at(row, 2),
        text: Enum.at(row, 3),
        inserted_at: Ecto.DateTime.to_iso8601(inserted_at)}
    end
  end
end
