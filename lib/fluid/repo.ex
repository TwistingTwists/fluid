defmodule Fluid.Repo do
  use AshPostgres.Repo,
    otp_app: :fluid

  def installed_extensions do
    [
      "ash-functions",
      "citext",
      "uuid-ossp"
    ]
  end
end
