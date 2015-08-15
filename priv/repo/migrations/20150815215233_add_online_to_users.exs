defmodule Shlack.Repo.Migrations.AddOnlineToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :online, :boolean, null: false, default: false
    end
  end
end
