defmodule IRC.Commands.Nick do
  require Logger
  @behaviour IRC.Commands.Base

  @impl IRC.Commands.Base
  def value(), do: IRC.Parsers.Message.Commands.NICK

  @doc """
  Set the client's nickname.

  Numeric replies:
    - ERR_NONICKNAMEGIVEN
    - ERR_ERRONEUSNICKNAME
    - ERR_NICKNAMEINUSE
    - ERR_NICKCOLLISION
  """
  @impl IRC.Commands.Base
  def run(parameters, client_state) do
    if length(parameters) == 0 do
      IRC.ClientConnection.send_to_client(
        client_state.socket,
        "server",
        IRC.Models.Errors.lookup(:ERR_NONICKNAMEGIVEN),
        ":No nickname given"
      )
    else
      # TODO
    end

    :ok
  end
end
