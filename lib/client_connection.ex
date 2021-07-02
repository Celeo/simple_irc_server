defmodule IRC.ClientConnection do
  use GenServer, restart: :transient
  require Logger

  # =============================================================================
  # Private API
  # =============================================================================

  def start_link(socket) do
    Logger.info("Starting new client connection")

    GenServer.start_link(__MODULE__, %{
      socket: socket,
      pid: nil,
      nick: nil,
      user: %IRC.Models.User{},
      modes: ""
    })
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  # Normal messages from the client.
  @impl true
  def handle_info({:tcp, socket, message}, state) do
    if IRC.Parsers.Message.strip_crlf(message) != "" do
      Logger.info("Got message from client: #{message}")

      # Command processing here is done in order to ensure
      # that the message is actually a valid command from
      # the user and to do some processing on the message
      # to make it easier for later consumption. Later
      # processing is responsible for actually determining
      # if the command is appropriate to use, uses sensible
      # values, etc.
      case IRC.Parsers.Message.parse_message(message) do
        {:ok, command, parameters} ->
          Logger.info("Got command #{command} from client")
          # send the command on
          IRC.Server.send_command(state, command, parameters)

        {:error, reason} ->
          trimmed_message =
            message
            |> IRC.Parsers.Message.strip_crlf()
            |> String.split(":")
            |> hd()
            |> String.trim()

          Logger.warning(
            "Could not parse command from client: #{trimmed_message} || because: #{reason}"
          )

          send_to_client(
            socket,
            ":server #{IRC.Models.Errors.lookup(:ERR_UNKNOWNCOMMAND)} #{trimmed_message} :Unknown command"
          )
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

  # Set the pid. Used when creating a new process of this module
  # so that it knows its own pid for use in calls and casts.
  @impl true
  def handle_call({:set_pid, pid}, _from, state) do
    messages = [
      ":server NOTICE * :*** Hello!",
      ":server NOTICE * :*** Waiting on your NICK and USER commands ..."
    ]

    Enum.each(messages, &IRC.ClientConnection.send_to_client(state.socket, &1))
    {:reply, :ok, %{state | pid: pid}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  # Set nickname.
  @impl true
  def handle_cast({:set_nickname, new_nick}, state) do
    new_state = %{state | nick: new_nick}
    {:noreply, new_state}
  end

  # Set user info.
  @impl true
  def handle_cast({:set_user, username, mode, real_name}, state) do
    new_user = %IRC.Models.User{user: username, mode: mode, real_name: real_name}
    new_state = %{state | user: new_user}
    {:noreply, new_state}
  end

  # =============================================================================
  # Public API
  # =============================================================================

  @doc """
  Send a message to the client.
  """
  @spec send_to_client(socket :: port(), message :: String.t()) :: :ok | tuple()
  def send_to_client(socket, message) do
    :gen_tcp.send(socket, "#{message}\r\n")
  end

  @doc """
  Force this process to end.
  """
  @spec force_disconnect(pid :: pid()) :: :ok
  def force_disconnect(pid) do
    GenServer.stop(pid)
  end

  @doc """
  Set the client's username.
  """
  @spec update_nickname(pid :: pid(), nick :: String.t()) :: :ok
  def update_nickname(pid, nick) do
    GenServer.cast(pid, {:set_nickname, nick})
  end

  @doc """
  Set the client's user information.
  """
  @spec update_user(
          pid :: pid(),
          username :: String.t(),
          mode :: String.t(),
          real_name :: String.t()
        ) :: :ok
  def update_user(pid, username, mode, real_name) do
    GenServer.cast(pid, {:set_user, username, mode, real_name})
  end

  @doc """
  Get the client's state.
  """
  @spec get_state(pid :: pid()) :: :ok
  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end
end
