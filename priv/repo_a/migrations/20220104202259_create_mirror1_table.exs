defmodule Ffiu.Repo.Migrations.CreateMirror1Table do
  use Ecto.Migration

  def change do
    create table(:mirror1, primary_key: false) do
      add :id, :bigint
      add :field, :string
    end

    create unique_index(:mirror1, :id)
  end
end
