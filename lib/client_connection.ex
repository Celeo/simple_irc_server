defmodule IRC.ClientConnection do
  use GenServer, restart: :transient
  require Logger

  @impl true
  def init(state) do
    {:ok, state}
  end

  def start_link(state) do
    Logger.info("Starting new client connection")
    GenServer.start_link(__MODULE__, state)
  end

  # Normal messages from the client.
  @impl true
  def handle_info({:tcp, _socket, message}, state) do
    IO.inspect(message)
    {:noreply, state}
  end

  # Socket closed
  @impl true
  def handle_info({:tcp_closed, _socket}, state) do
    Logger.info("Socket has been closed")
    {:stop, :normal, state}
  end

  # Socket had an error
  @impl true
  def handle_info({:tcp_error, _socket, reason}, state) do
    Logger.info("Connection closed: #{reason}")
    {:noreply, state}
  end

  # Other event
  @impl true
  def handle_info(_event, state) do
    {:noreply, state}
  end
end
