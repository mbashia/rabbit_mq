defmodule RabbitMq.RabbitmqConnection do

  use GenServer
  require Logger

  @reconnect_interval 5_000

end
