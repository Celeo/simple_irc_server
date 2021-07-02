defmodule IRC.Commands.Nick do
  require Logger
  @behaviour IRC.Commands.Base

  @nickname_regex ~r/^[a-z0-9_\-\[\]\(\)\\\{\}\|]{1,9}$/i

  @doc """
  Set the client's nickname.

  Numeric replies:
    - ERR_NONICKNAMEGIVEN
    - ERR_ERRONEUSNICKNAME
    - ERR_NICKNAMEINUSE
    - ERR_NICKCOLLISION
  """
  @impl IRC.Commands.Base
  def run(parameters, client_state, server_state) do
    requested_nickname = Enum.at(parameters, 0, "")

    case valid_username(requested_nickname) do
      :ok ->
        this_client =
          server_state.clients
          |> Map.keys()
          |> Enum.find(fn key ->
            server_state.clients[key] == client_state.pid
          end)

        someone_using_nick =
          server_state.clients
          |> Map.keys()
          |> Enum.find(fn key ->
            key == requested_nickname
          end) != nil

        case {this_client, someone_using_nick} do
          {nil, true} ->
            IRC.ClientConnection.send_to_client(
              client_state.socket,
              ":server #{IRC.Models.Errors.lookup(:ERR_NICKCOLLISION)} :Nickname collision KILL"
            )

            IRC.ClientConnection.force_disconnect(client_state.pid)
            :ok

          {nil, false} ->
            Task.start(fn ->
              IRC.ClientConnection.update_nickname(client_state.pid, requested_nickname)
              IRC.Server.connect_client(client_state.pid, requested_nickname)
            end)

            :ok

          {_, true} ->
            IRC.ClientConnection.send_to_client(
              client_state.socket,
              ":server #{IRC.Models.Errors.lookup(:ERR_NICKNAMEINUSE)} :Nickname is already in use"
            )

            {:error, "Nickname is already in use"}

          {_, false} ->
            # TODO need to notify other clients of the change i.e.:
            # :WiZ!jto@tolsun.oulu.fi NICK Kilroy
            Task.start(fn -> IRC.Server.change_nickname(client_state.nick, requested_nickname) end)

            :ok
        end

      {:error, num, msg} ->
        IRC.ClientConnection.send_to_client(client_state.socket, ":server #{num} #{msg}")
        {:error, msg}
    end
  end

  @doc """
  Check if the supplied username is valid.

  The following conditions are checked:

  1. Username is not empty
  2. Username is made of acceptable characters.
  3. Username is the appropriate length of [1, 9]
  """
  @spec valid_username(name :: String.t(), check :: atom()) ::
          :ok | {:error, number :: integer(), message :: String.t()}
  def valid_username(name, check \\ :present) do
    case check do
      :present ->
        case String.length(name) do
          0 -> {:error, IRC.Models.Errors.lookup(:ERR_NONICKNAMEGIVEN), ":No nickname given"}
          _ -> valid_username(name, :content)
        end

      :content ->
        if String.match?(name, @nickname_regex) do
          :ok
        else
          {:error, IRC.Models.Errors.lookup(:ERR_ERRONEUSNICKNAME), ":Erroneus nickname"}
        end
    end
  end
end
