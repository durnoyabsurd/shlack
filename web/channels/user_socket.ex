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
    user = name && (Repo.get_by(User, name: name) || register_user(name, socket))

    if user do
      {:ok, assign(socket, :user, user)}
    else
      :error
    end
  end

  def id(socket), do: "users_socket:#{socket.assigns.user.id}"

  defp register_user(name, socket) do
    user = Repo.insert!(%User{name: name})
    Endpoint.broadcast! "user", "user_registered", %{user: user.name}
    user
  end
end
