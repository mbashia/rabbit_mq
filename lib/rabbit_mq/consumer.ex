defmodule RabbitMq.Consumer do
  def start do
    case AMQP.Connection.open() do
      {:ok, connection} ->
        case AMQP.Channel.open(connection) do
          {:ok, channel} ->
            # Declare queue
            AMQP.Queue.declare(channel, "hello")

            # Start consuming
            case AMQP.Basic.consume(channel, "hello", nil, no_ack: true) do
              {:ok, _consumer_tag} ->
                IO.puts(" [*] Waiting for messages. To exit press CTRL+C")
                wait_for_messages()

              error ->
                IO.puts(" [!] Failed to start consuming: #{inspect(error)}")
                AMQP.Connection.close(connection)
            end

          error ->
            IO.puts(" [!] Failed to open channel: #{inspect(error)}")
            AMQP.Connection.close(connection)
        end

      error ->
        IO.puts(" [!] Failed to connect: #{inspect(error)}")
    end
  end

  defp wait_for_messages do
    receive do
      {:basic_deliver, payload, meta} ->
        IO.puts(" [x] Received: #{payload}")
        IO.puts("     Routing key: #{meta.routing_key}")
        IO.puts("     Delivery tag: #{meta.delivery_tag}")
        wait_for_messages()

      other ->
        IO.puts(" [?] Unexpected message: #{inspect(other)}")
        wait_for_messages()
    end
  end
end
