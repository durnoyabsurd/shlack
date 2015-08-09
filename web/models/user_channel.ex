defmodule Shlack.UserChannel do
  use Shlack.Web, :model

  schema "user_channels" do
    belongs_to :user, Shlack.User
    belongs_to :channel, Shlack.Channel

    timestamps
  end

  @required_fields ~w(user_id channel_id)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_unique([:user_id, :channel_id], on: Repo)
  end
end
