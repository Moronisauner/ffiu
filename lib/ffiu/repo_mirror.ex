defmodule Ffiu.RepoMirror do
  use Ecto.Repo,
    otp_app: :ffiu,
    adapter: Ecto.Adapters.Postgres
end
