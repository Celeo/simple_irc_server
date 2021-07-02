defmodule IRC.Commands.Who do
  require Logger
  @behaviour IRC.Commands.Base

  # << WHO cel*
  # >> :platinum.libera.chat 352 Celeo * ~Celeo user/celeo platinum.libera.chat Celeo H :0 Celeo
  # >> :platinum.libera.chat 352 Celeo * sid97751 id-97751.brockwell.irccloud.com tungsten.libera.chat celphi G :0 rybka
  # >> :platinum.libera.chat 352 Celeo * ~celeste1m 2001:470:69fc:105::3ea9 zirconium.libera.chat celeste1 H :0 @celeste1:matrix.org
  # >> :platinum.libera.chat 352 Celeo * ~slep cpc150002-brnt4-2-0-cust437.4-2.cable.virginm.net osmium.libera.chat slep G :0 Celeste
  # >> :platinum.libera.chat 352 Celeo * celelibi user/celelibi cadmium.libera.chat Celelibi H :0 Alors, il est beau mon whois ?
  # >> :platinum.libera.chat 315 Celeo cel* :End of /WHO list.

  @impl IRC.Commands.Base
  def run(_parameters, client_state, server_state) do
    # TODO implement search
    # TODO respect +i
    # TODO 315 RPL_ENDOFWHO reply at end when needed

    # IO.inspect(server_state.clients)
    # IO.inspect(Map.to_list(server_state.clients))

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
