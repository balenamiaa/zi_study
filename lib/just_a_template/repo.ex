defmodule JustATemplate.Repo do
  use Ecto.Repo,
    otp_app: :just_a_template,
    adapter: Ecto.Adapters.SQLite3
end
