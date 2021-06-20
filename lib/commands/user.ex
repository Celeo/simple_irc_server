defmodule IRC.Commands.User do
  @behaviour IRC.Commands.Base

  @impl IRC.Commands.Base
  def value(), do: IRC.Parsers.Message.Commands.USER

  @impl IRC.Commands.Base
  def run(_parameters, _client_pid, _client_state) do
    # TODO
    :ok
  end
end
