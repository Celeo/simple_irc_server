defmodule IRC.Server do
  use GenServer
  require Logger

  @impl true
  def init(_) do
    {:ok, nil}
  end

  def start_link(_) do
    Logger.info("Starting server")
    GenServer.start_link(__MODULE__, %{connected: %{}, channels: %{}}, name: IRC.Server)
  end

  @impl true
  def handle_cast({:command, _client_pid, _command, _parameters}, state) do
    # TODO
    {:noreply, state}
  end

  @impl true
  def handle_cast(_event, state) do
    {:noreply, state}
  end

  @doc """
  TODO
  """
  @spec connect_client(client_pid :: pid()) :: :ok
  def connect_client(_client_pid) do
    # TODO
    :ok
  end

  @doc """
  Send a command to the "server". The message has already
  reached the server at this point, but this function is for
  having the server handle the command that's

  1. reached the server from the user's client, and
  2. been processed into a valid command and parameters.
  """
  @spec send_command(client_pid :: pid(), command :: String.t(), parameters :: tuple()) :: :ok
  def send_command(client_pid, command, parameters) do
    GenServer.cast(__MODULE__, {:command, client_pid, command, parameters})
  end
end
