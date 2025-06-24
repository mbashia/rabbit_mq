defmodule RabbitMq.Publisher do
  alias RabbitMq.RabbitmqConnection

  def publish(message) do
    case RabbitmqConnection.get_connection() do
      {:ok, connection} ->
        # use default exchange
        {:ok, channel} = AMQP.Channel.open(connection)

        ## make sure recipient queue exists
        AMQP.Queue.declare(channel, "hello")
        |> case do
          {:ok, _} ->
            ## use default exchange, the name of the queue acts as the routing key
            AMQP.Basic.publish(channel, "", "hello", message)

            # :ok = AMQP.Connection.close(connection)

          error ->
            error
        end

      error ->
        error
    end
  end
end
