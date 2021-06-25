defmodule IRC.Commands.Nick do
  require Logger
  @behaviour IRC.Commands.Base

  @impl IRC.Commands.Base
  def value(), do: IRC.Parsers.Message.Commands.NICK

  # TODO
  @doc """
  Set the client's nickname.

  Numeric replies:
    - ERR_NONICKNAMEGIVEN
    - ERR_ERRONEUSNICKNAME
    - ERR_NICKNAMEINUSE
    - ERR_NICKCOLLISION
  """
  @impl IRC.Commands.Base
  def run(_parameters, _client_state) do
    # ...

    :ok
  end
end
