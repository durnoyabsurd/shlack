defmodule Shlack.UserChannelTest do
  use Shlack.ModelCase

  alias Shlack.UserChannel

  @valid_attrs %{channel_id: 42, user_id: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = UserChannel.changeset(%UserChannel{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = UserChannel.changeset(%UserChannel{}, @invalid_attrs)
    refute changeset.valid?
  end
end
