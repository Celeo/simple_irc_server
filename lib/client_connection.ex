defmodule IRC.ClientConnection do
  use GenServer, restart: :transient
  require Logger

  @impl true
  def init(socket) do
    {:ok, socket}
  end

  def start_link(socket) do
    Logger.info("Starting new client connection")
    GenServer.start_link(__MODULE__, %{socket: socket, pid: nil})
  end

  # Normal messages from the client.
  @impl true
  def handle_info({:tcp, socket, message}, state) do
    Logger.info("Got message from client: #{message}")

    # Command processing here is done in order to ensure
    # that the message is actually a valid command from
    # the user, contains the correct minimum number of
    # parameters, and to do some processing on the message
    # to make it easier for later consumption.
    # Later processing is responsible for actually determining
    # if the command is appropriate to use, uses sensible
    # values, etc.
    case IRC.Parsers.Message.parse_message(message) do
      {:ok, command, parameters} ->
        Logger.info("Got command #{command} from client")
        send_to_server(state.pid, command, parameters)

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

  # All other events
  @impl true
  def handle_info(_event, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call({:set_pid, pid}, _from, state) do
    {:reply, :ok, %{state | pid: pid}}
  end

  defp send_to_client(socket, source, code, message) do
    :gen_tcp.send(socket, ":#{source} #{code} #{message}\r\n")
  end

  defp send_to_server(client_pid, command, parameters) do
    IRC.Server.send_command(client_pid, command, parameters)
  end
end
