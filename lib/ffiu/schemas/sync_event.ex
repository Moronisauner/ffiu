defmodule Ffiu.Schemas.SyncEvent do
  use Ecto.Schema

  schema "sync_events" do
    field :row, :map
    field :table, :string
    field :command, :string
    field :received, :boolean

    timestamps()
  end
end
