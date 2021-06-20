defmodule IRC.Commands.Nick do
  require Logger
  @behaviour IRC.Commands.Base

  @impl IRC.Commands.Base
  def value(), do: IRC.Parsers.Message.Commands.NICK

  # TODO
  @impl IRC.Commands.Base
  def run(_parameters, _client_pid, _client_state) do
    Logger.warning("--- In IRC.Commands.Nick :: run() ---")

    :ok
  end
end
