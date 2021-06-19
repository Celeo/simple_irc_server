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

  @doc """
  Send a command to the "server". The message has already
  reached the server at this point, but this function is for
  having the server handle the command that's:

  1. Reached the server
  2. Been processed into a valid command and parameters
  """
  @spec send_command(String.t(), list()) :: tuple()
  def send_command(_command, _parameters) do
    # TODO
    {:ok}
  end

  # Send a message to a single client.
  @spec send_to_client(String.t(), String.t()) :: nil
  defp send_to_client(_nickname, _message) do
    # TODO
  end

  # Send a message to all connected clients.
  @spec send_to_all_clients(String.t()) :: nil
  defp send_to_all_clients(_message) do
    # TODO
  end
end
