defmodule Ffiu.Repo.Migrations.CreateMessageTable do
  use Ecto.Migration

  def change do
    create table(:sync_events) do
      add :row, :jsonb, null: false
      add :table, :string, null: false
      add :command, :string, null: false
      add :received, :boolean, default: false

      timestamps()
    end
  end
end
