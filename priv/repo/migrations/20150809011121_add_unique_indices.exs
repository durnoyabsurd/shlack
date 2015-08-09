defmodule Shlack.Repo.Migrations.AddUniqueIndices do
  use Ecto.Migration

  def change do
    execute "CREATE UNIQUE INDEX users_name_unique_idx ON users (name)"
    execute "CREATE UNIQUE INDEX channels_name_unique_idx ON channels (name)"
  end
end
