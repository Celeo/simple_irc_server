defmodule IRC.Commands.Nick do
  require Logger
  @behaviour IRC.Commands.Base

  @nickname_regex ~r/^[a-z0-9_\-\[\]\(\)\\\{\}\|]{1,9}$/i

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
    case valid_username(Enum.at(parameters, 0, "")) do
      :ok ->
        # TODO
        #   - if the user is setting their nick for the first time
        #     and it matches a nick already on the server, then send
        #     ERR_NICKCOLLISION
        #   - if the user is changing their existing nick and the new
        #     name matches a nick already on the server, then send
        #     ERR_NICKCOLLISION

        server_state = IRC.Server.get_state() |> IO.inspect()

        :ok

      err = {:error, num, msg} ->
        IRC.ClientConnection.send_to_client(client_state.socket, "server", num, msg)
        err
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
