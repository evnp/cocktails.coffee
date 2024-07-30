defmodule CocktailsCoffee.Repo do
  use Ecto.Repo,
    otp_app: :cocktails_coffee,
    adapter: Ecto.Adapters.Postgres
end
