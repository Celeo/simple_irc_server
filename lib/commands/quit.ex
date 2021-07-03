defmodule IRC.Commands.Quit do
  require Logger
  @behaviour IRC.Commands.Base

  @doc """
  Session exits the server.
  """
  @impl IRC.Commands.Base
  def run(parameters, client_state, _server_state) do
    if client_state.user.user != nil do
      IRC.ClientConnection.force_disconnect(client_state.pid)
      IRC.Server.forget_client(client_state.pid)

      quit_message =
        if length(parameters) > 0 do
          hd(parameters)
        else
          "Disconnected"
        end

      IRC.Server.broadcast_message(
        ":#{client_state.nick}!#{client_state.user.user}@localhost QUIT: #{quit_message}"
      )
    end
  end
end
