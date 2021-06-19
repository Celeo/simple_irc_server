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
  def handle_info({:tcp, socket, message}, state) do
    Logger.info("Got message from client: #{message}")

    case IRC.Parsers.Message.parse_message(message) do
      {:ok, command, parameters} ->
        send_to_server(socket, message, command, parameters)

      {:error, reason} ->
        Logger.warning("Could not parse command from client: #{reason}")

        cond do
          String.contains?(reason, "Need more parameters") ->
            send_to_client(socket, "server", 461, "#{message} :Not enough parameters")

          true ->
            send_to_client(socket, "server", 421, "#{message} :Unknown command")
        end
    end

    {:noreply, state}
  end

  # Socket was closed
  @impl true
  def handle_info({:tcp_closed, _socket}, state) do
    Logger.info("Socket closed by the client")
    {:stop, :normal, state}
  end

  # Socket had an error
  @impl true
  def handle_info({:tcp_error, _socket, reason}, state) do
    Logger.warning("Socket error: #{reason}")
    {:noreply, state}
  end

  # Other event
  @impl true
  def handle_info(_event, state) do
    {:noreply, state}
  end

  defp send_to_client(socket, source, code, message) do
    :gen_tcp.send(socket, ":#{source} #{code} #{message}\r\n")
  end

  defp send_to_server(_socket, _message, command, parameters) do
    Logger.info("Got command #{command} from client")
    IRC.Server.send_command(command, parameters)
    # TODO handle response
  end
end
