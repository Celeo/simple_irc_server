defmodule IRC.Commands.User do
  @behaviour IRC.Commands

  @impl IRC.Commands
  def value(), do: IRC.Parsers.Message.Commands.USER

  @impl IRC.Commands
  def run(_parameters, _client_pid, _client_state, _server_state) do
    # TODO
    :ok
  end
end
