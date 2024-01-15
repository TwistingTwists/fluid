defmodule Fluid.Repo do
  use Ecto.Repo,
    otp_app: :fluid,
    adapter: Ecto.Adapters.Postgres
end
