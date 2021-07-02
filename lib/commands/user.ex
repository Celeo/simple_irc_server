defmodule IRC.Commands.User do
  require Logger
  use Bitwise
  @behaviour IRC.Commands.Base

  @doc """
  Update the user information.

  Numeric replies:
    - ERR_NEEDMOREPARAMS
    - ERR_ALREADYREGISTRED
  """
  @impl IRC.Commands.Base
  def run(parameters, client_state, _server_state) do
    nick = client_state.nick

    cond do
      nick == nil ->
        Logger.debug("Client sent USER before NICK, disconnecting them")
        IRC.ClientConnection.force_disconnect(client_state.pid)

      client_state.user.user != nil ->
        IRC.ClientConnection.send_to_client(
          client_state.socket,
          ":server #{IRC.Models.Errors.lookup(:ERR_ALREADYREGISTRED)} :Unauthorized command (already registered)"
        )

      length(parameters) < 4 ->
        Logger.debug(
          "Insufficient number of parameters for USER command (got #{length(parameters)}"
        )

        IRC.ClientConnection.send_to_client(
          client_state.socket,
          ":server #{IRC.Models.Errors.lookup(:ERR_NEEDMOREPARAMS)} NICK :Not enough parameters"
        )

      true ->
        {user, mode, _, real_name} = List.to_tuple(parameters)

        mode =
          mode
          |> String.to_integer()
          |> mode_to_letters()

        Logger.debug("Got valid USER command from #{nick}: #{user}, #{mode}, #{real_name}")

        Task.start_link(fn ->
          IRC.ClientConnection.update_user(
            client_state.pid,
            user,
            mode,
            real_name
          )

          messages = [
            ":server 001 #{nick} :Welcome to theInternet Relay Network #{nick}!#{user}@localhost",
            ":server 002 #{nick} :Your host is localhost, running version IN_DEV",
            ":server 003 #{nick} :This server was created SOME TIME IN THE RECENT PAST",
            ":server 004 #{nick} :localhost IN_DEV aiwroOs bcCefFgiIjklmnpqQrsStuz"
          ]

          Enum.each(messages, &IRC.ClientConnection.send_to_client(client_state.socket, &1))
        end)
    end

    :ok
  end

  @doc """
  Parse a numeric bitmask of user mode for the USER command
  into its alpha representation.
  """
  @spec mode_to_letters(mode :: integer()) :: String.t()
  def mode_to_letters(mode) do
    mode_i =
      if mode >>> 3 do
        "i"
      else
        ""
      end

    mode_w =
      if mode >>> 2 do
        "w"
      else
        ""
      end

    Enum.join([
      mode_i,
      mode_w
    ])
  end
end
