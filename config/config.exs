# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :discuss,
       ecto_repos: [Discuss.Repo]

# Configures the endpoint
config :discuss,
       DiscussWeb.Endpoint,
       url: [
         host: "localhost"
       ],
       secret_key_base: "9LZ+YewLAiDpiIblv1m+9cSVdhi6ZKGLJUu/uobRtXUpKmymrfKa8Gxl8bTowGqJ",
       render_errors: [
         view: DiscussWeb.ErrorView,
         accepts: ~w(html json),
         layout: false
       ],
       pubsub_server: Discuss.PubSub,
       live_view: [
         signing_salt: "lw9yyy3T"
       ]

# Configures Elixir's Logger
config :logger,
       :console,
       format: "$time $metadata[$level] $message\n",
       metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

config :goth,
       json: "./config/service_account.json"
             |> File.read!


config :elixir_google_spreadsheets,
       :client,
       request_workers: 50