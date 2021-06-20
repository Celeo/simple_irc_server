defmodule IRC.Commands.Base do
  @doc """
  Returns the command enum entry.
  """
  @callback value() :: IRC.Parsers.Message.Commands.t()

  @doc """
  Process the command.
  """
  @callback run(
              parameters :: tuple(),
              client_pid :: pid(),
              client_state :: map()
            ) :: :ok | {:error, String.t()}
end
