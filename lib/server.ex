defmodule IRC.Server do
  use GenServer
  require Logger

  # =============================================================================
  # Internal API
  # =============================================================================

  @impl true
  def init(state) do
    {:ok, state}
  end

  @doc """
  Process's state:
  ```
    %{
      clients: %{
        [nickname]: [client pid]
      },
      channels: %{
        [name]: [data struct]
      },
    }
  ```
  """
  def start_link(_) do
    Logger.info("Starting server")
    GenServer.start_link(__MODULE__, %{clients: %{}, channels: %{}}, name: __MODULE__)
  end

  @impl true
  def handle_cast({:command, client_state, command, parameters}, state) do
    Logger.debug("Starting processing of command #{command}")
    {_, module_suffix, _} = IRC.Parsers.Message.Commands.matching_value(command)

    Task.start(fn ->
      atom_name = "Elixir.IRC.Commands.#{module_suffix}"

      try do
        apply(String.to_existing_atom(atom_name), :run, [
          parameters,
          client_state,
          state
        ])
      rescue
        _e in ArgumentError ->
          Logger.warn("Could not find module & function for: #{atom_name}")
      end
    end)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:broadcast, message}, state) do
    Logger.debug("Broadcasting message: #{message}")

    Enum.each(Map.values(state.clients), fn client_pid ->
      client_state = IRC.ClientConnection.get_state(client_pid)
      IRC.ClientConnection.send_to_client(client_state.socket, message)
    end)

    {:noreply, state}
  end

  # Get the state
  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  # Store a client pid in the state
  @impl true
  def handle_call({:connect_client, client_pid, nickname}, _from, state) do
    new_clients = Map.put(state.clients, nickname, client_pid)
    new_state = %{state | clients: new_clients}
    Logger.info("Server state updated with new client #{nickname}")
    {:reply, :ok, new_state}
  end

  # Change a client's nickname in the state
  @impl true
  def handle_call({:change_nickname, from, to}, _from, state) do
    {client_pid, new_clients} = Map.pop!(state.clients, from)
    new_clients = Map.put(new_clients, to, client_pid)
    new_state = %{state | clients: new_clients}
    Logger.debug("Server state updated with client rename #{from} -> #{to}")
    {:reply, :ok, new_state}
  end

  # Remove a client from the state.
  @impl true
  def handle_call({:forget_client, client_pid}, _from, state) do
    {nick_to_remove, _} = Enum.find(state.clients, fn {_, pid} -> pid == client_pid end)
    Logger.debug("Removing \"#{nick_to_remove}\" from server state")
    new_clients = Map.delete(state.clients, nick_to_remove)
    {:reply, :ok, %{state | clients: new_clients}}
  end

  # =============================================================================
  # Public API
  # =============================================================================

  @doc """
  Send a command to the "server". The message has already
  reached the server at this point, but this function is for
  having the server handle the command that's

  1. reached the server from the user's client, and
  2. been processed into a valid command and parameters.
  """
  @spec send_command(
          client_state :: map(),
          command :: String.t(),
          parameters :: list()
        ) :: :ok
  def send_command(client_state, command, parameters) do
    GenServer.cast(__MODULE__, {:command, client_state, command, parameters})
  end

  @doc """
  Get the server's stored state.
  """
  @spec get_state() :: map()
  def get_state() do
    GenServer.call(__MODULE__, :get_state)
  end

  @doc """
  Connect a client process to this server.
  """
  @spec connect_client(client_pid :: pid(), nickname :: String.t()) :: :ok
  def connect_client(client_pid, nickname) do
    GenServer.call(__MODULE__, {:connect_client, client_pid, nickname})
  end

  @doc """
  Change a client's nickname.
  """
  @spec change_nickname(from :: String.t(), to :: String.t()) :: :ok
  def change_nickname(from, to) do
    GenServer.call(__MODULE__, {:change_nickname, from, to})
  end

  @doc """
  Remove a client from the state.
  """
  @spec forget_client(client_pid :: pid()) :: :ok
  def forget_client(client_pid) do
    GenServer.call(__MODULE__, {:forget_client, client_pid})
  end

  @doc """
  Broadcast a message to all connected clients.
  """
  @spec broadcast_message(message :: String.t()) :: :ok
  def broadcast_message(message) do
    GenServer.cast(__MODULE__, {:broadcast, message})
  end
end
