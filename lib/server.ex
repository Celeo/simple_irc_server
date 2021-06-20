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
  def handle_cast({:command, client_pid, command, parameters}, state) do
    Logger.info("Need to process command #{command}")
    {_, _, _, module_suffix} = IRC.Parsers.Message.Commands.matching_value(command)

    result =
      apply(String.to_existing_atom("Elixir.IRC.Commands.#{module_suffix}"), :run, [
        parameters,
        client_pid,
        state
      ])

    case result do
      :ok -> :noop
      {:error, reason} -> Logger.warning("Error processing command #{command}: #{reason}")
    end

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
