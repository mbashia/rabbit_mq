defmodule RabbitMq.Repo do
  use Ecto.Repo,
    otp_app: :rabbit_mq,
    adapter: Ecto.Adapters.Postgres
end
