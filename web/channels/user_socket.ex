defmodule Shlack.UserSocket do
  use Phoenix.Socket

  alias Shlack.Endpoint
  alias Shlack.Repo
  alias Shlack.User
  alias Shlack.Channel

  channel "rooms:*", Shlack.RoomChannel

  transport :websocket, Phoenix.Transports.WebSocket
  transport :longpoll, Phoenix.Transports.LongPoll

  def connect(params, socket) do
    name = params["username"]
    user = name && find_or_register_user(name, socket)

    if user do
      {:ok, assign(socket, :user, user)}
    else
      :error
    end
  end

  def id(socket), do: "users_socket:#{socket.assigns.user.id}"

  defp find_or_register_user(name, socket) do
    user = Repo.get_by(User, name: name)

    if user do
      put_online(user)
    else
      register_user(name, socket)
    end
  end

  defp put_online(user) do
    Repo.update!(%{user | online: true})
  end

  defp register_user(name, socket) do
    Repo.insert!(%User{name: name, online: true})
  end
end
