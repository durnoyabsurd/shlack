defmodule Shlack.Channel do
  use Shlack.Web, :model

  schema "channels" do
    field :name, :string
    has_many :messages, Shlak.Message
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
