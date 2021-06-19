defmodule IRC.Server do
  use GenServer
  require Logger

  @impl true
  def init(state) do
    {:ok, state}
  end

  def start_link(state) do
    Logger.info("Starting server")
    GenServer.start_link(__MODULE__, state, name: IRC.Server)
  end

  @impl true
  def handle_cast({:command, _client_pid, _command, _parameters}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast(_event, state) do
    {:noreply, state}
  end

  @doc """
  Send a command to the "server". The message has already
  reached the server at this point, but this function is for
  having the server handle the command that's:

  1. Reached the server
  2. Been processed into a valid command and parameters
  """
  def send_command(client_pid, command, parameters) do
    GenServer.cast(__MODULE__, {:command, client_pid, command, parameters})
  end
end
