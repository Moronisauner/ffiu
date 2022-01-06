defmodule Ffiu.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Ffiu.Repo,
      Ffiu.RepoMirror,
      FfiuWeb.Telemetry,
      {Phoenix.PubSub, name: Ffiu.PubSub},
      FfiuWeb.Endpoint,
      {Postgrex.Notifications, notifications_config()},
      MyListener,
      {Ffiu.SyncPooler, delay: :timer.seconds(10)}
    ]

    opts = [strategy: :one_for_one, name: Ffiu.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    FfiuWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp notifications_config do
    :ffiu
    |> Application.get_all_env()
    |> Keyword.get(Ffiu.Repo)
    |> IO.inspect(label: "Config to connect")
    |> Keyword.merge(name: Ffiu.Notifications)
  end
end
