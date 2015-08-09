defmodule Shlack.User do
  use Shlack.Web, :model

  schema "users" do
    field :name, :string
    has_many :messages, Shlack.Message
    has_many :user_channels, Shlack.UserChannel
    has_many :channels, through: [:user_channels, :channel]

    timestamps
  end

  @required_fields ~w(name)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_unique(:name, on: Repo)
  end
end
