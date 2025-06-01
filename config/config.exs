# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :zi_study, ZiStudy.Repo,
  database: "zi_study_repo",
  username: "user",
  password: "pass",
  hostname: "localhost"

config :zi_study, :scopes,
  user: [
    default: true,
    module: ZiStudy.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: ZiStudy.AccountsFixtures,
    test_login_helper: :register_and_log_in_user
  ]

config :zi_study,
  ecto_repos: [ZiStudy.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :zi_study, ZiStudyWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ZiStudyWeb.ErrorHTML, json: ZiStudyWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ZiStudy.PubSub,
  live_view: [signing_salt: "TjW5907C"]

config :zi_study, ZiStudy.Mailer, adapter: Swoosh.Adapters.Local

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.0.9",
  zi_study: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
