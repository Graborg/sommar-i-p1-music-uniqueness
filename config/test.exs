use Mix.Config

# Configure your database
config :sommar_i_p1, SommarIP1.Repo,
  username: "postgres",
  password: "postgres",
  database: "sommar_i_p1_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :sommar_i_p1, SommarIP1Web.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
