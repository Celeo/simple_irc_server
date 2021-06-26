defmodule IRC.Commands.Base do
  @doc """
  Returns the command enum entry.
  """
  @callback value() :: IRC.Parsers.Message.Commands.t()

  @doc """
  Process the command.

  This command is responsible for executing the entire "life" of the
  command, including sending information to the issuing client and
  sending information to other clients.
  """
  @callback run(
              parameters :: tuple(),
              client_state :: map(),
              server_state :: map()
            ) :: :ok | {:error, String.t()}
end
