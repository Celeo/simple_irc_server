defmodule IRC.Commands.Who do
  require Logger
  @behaviour IRC.Commands.Base

  @impl IRC.Commands.Base
  def run(_parameters, client_state, server_state) do
    # TODO implement search
    # TODO respect +i
    # TODO 315 RPL_ENDOFWHO reply at end when needed

    Task.start(fn ->
      Enum.each(Map.to_list(server_state.clients), fn {nick, client_pid} ->
        state = IRC.ClientConnection.get_state(client_pid)
        msg = user_to_string(state.user, nick)

        IRC.ClientConnection.send_to_client(
          client_state.socket,
          ":server #{IRC.Models.Errors.lookup(:RPL_WHOREPLY)} #{client_state.nick} #{msg}"
        )
      end)
    end)

    :ok
  end

  defp user_to_string(user_info, nick) do
    "* #{user_info.user} localhost server #{nick} * :0 #{user_info.real_name}"
  end
end
