import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :ffiu, Ffiu.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "ffiu_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  priv: "priv/repo_a"

config :ffiu, Ffiu.RepoMirror,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "ffiu_mirror_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  priv: "priv/repo_b"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ffiu, FfiuWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "SnZ+0aozjoE8rIU6LlffsvOTkCCTCVrZ4c5ohibh9c3OEdIbe0rGE4dk03wxHp7L",
  server: false

# In test we don't send emails.
config :ffiu, Ffiu.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
