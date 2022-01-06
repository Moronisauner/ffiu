defmodule Ffiu.RepoMirror.Migrations.CreateConsumedMessages do
  use Ecto.Migration

  def change do
    create table(:consumed) do
      add :result, :string
    end
  end
end
