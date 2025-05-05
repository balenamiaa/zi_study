defmodule Zistudy.Repo do
  use Ecto.Repo,
    otp_app: :zistudy,
    adapter: Ecto.Adapters.SQLite3
end
