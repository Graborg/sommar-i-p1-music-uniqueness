# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :sommar_i_p1,
  ecto_repos: [SommarIP1.Repo]

# Configures the endpoint
config :sommar_i_p1, SommarIP1Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "K+AtAjs83uCqRdSA0te1hj5bLyayag6VqmGTyztgkRNsyPvWDlq0fvavAza3E+UP",
  render_errors: [view: SommarIP1Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: SommarIP1.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
