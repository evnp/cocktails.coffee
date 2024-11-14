defmodule Cc.Repo do
  use Ecto.Repo,
    otp_app: :cc,
    adapter: Ecto.Adapters.Postgres
end
