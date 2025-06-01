defmodule ZiStudy.Repo do
  use Ecto.Repo,
    otp_app: :zi_study,
    adapter: Ecto.Adapters.SQLite3
end
