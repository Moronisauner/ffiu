defmodule Ffiu.Schemas.Consumed do
  use Ecto.Schema

  schema "consumed" do
    field :result, :string
  end
end
