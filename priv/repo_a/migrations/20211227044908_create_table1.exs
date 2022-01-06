defmodule Ffiu.Repo.Migrations.CreateTable1 do
  use Ecto.Migration

  def change do
    create table(:table1) do
      add :field, :string
    end
  end
end
