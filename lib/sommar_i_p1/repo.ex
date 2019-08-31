defmodule SommarIP1.Repo do
  use Ecto.Repo,
    otp_app: :sommar_i_p1,
    adapter: Ecto.Adapters.Postgres
end
