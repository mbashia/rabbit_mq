defmodule RabbitMq.RabbitmqConnection do
  use GenServer
  require Logger

  @reconnect_interval 5_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_connection do
    GenServer.call(__MODULE__, :get_connection)
  end

  @impl true
  def init(_opts) do
    {:ok, nil, {:continue, :connect}}
  end

  @impl true
  def handle_call(:get_connection, _from, connection) do
    {:reply, {:ok, connection}, connection}
  end

  @impl true
  def handle_continue(:connect, _state) do
    case setup_connection() do
      {:ok, connection} ->
        Process.monitor(connection.pid)
        # Start a periodic heartbeat check
        schedule_connection_check()
        {:noreply, connection}

      {:error, reason} ->
        Logger.error("Failed to connect to RabbitMQ: #{inspect(reason)}")
        # Exponential backoff for reconnection attempts
        Process.sleep(1000)
        {:noreply, nil, {:continue, :connect}}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, reason}, _state) do
    Logger.error("RabbitMQ connection down: #{inspect(reason)}")
    {:noreply, nil, {:continue, :connect}}
  end

  @impl true
  def handle_info(:check_connection, connection) do
    # Logger.debug(
    #   "==========called to check connection: Connection is #{if Process.alive?(connection.pid), do: "alive", else: "dead"}==========="
    # )

    schedule_connection_check()

    case connection do
      nil ->
        {:noreply, nil, {:continue, :connect}}

      conn ->
        if Process.alive?(conn.pid) do
          {:noreply, connection}
        else
          {:noreply, nil, {:continue, :connect}}
        end
    end
  end

  defp setup_connection() do
    case AMQP.Connection.open() do
      {:ok, connection} ->
        {:ok, connection}

      {:error, reason} ->
        Logger.error("Failed to connect to RabbitMQ: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp schedule_connection_check() do
    Process.send_after(self(), :check_connection, @reconnect_interval)
  end
end
