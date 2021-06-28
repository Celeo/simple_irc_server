defmodule IRC.Parsers.Message do
  use EnumType

  @message_max_length 512

  # {
  #   Enum Name,
  #   {
  #     String value
  #     Module name suffix
  #     If last param is multi-word
  #   }
  # }
  defenum Commands do
    value(ADMIN, {"ADMIN", "Admin", false})
    value(CONNECT, {"CONNECT", "Connect", false})
    value(ERROR, {"ERROR", "Error", false})
    value(INFO, {"INFO", "Info", false})
    value(INVITE, {"INVITE", "Invite", false})
    value(JOIN, {"JOIN", "Join", false})
    value(KICK, {"KICK", "Kick", false})
    value(KILL, {"KILL", "Kill", false})
    value(LINKS, {"LINKS", "Links", false})
    value(LIST, {"LIST", "List", false})
    value(MODE, {"MODE", "Mode", false})
    value(NAMES, {"NAMES", "Names", false})
    value(NICK, {"NICK", "Nick", false})
    value(NOTICE, {"NOTICE", "Notice", true})
    value(OPER, {"OPER", "Oper", false})
    value(PART, {"PART", "Part", false})
    value(PASS, {"PASS", "Pass", false})
    value(PING, {"PING", "Ping", false})
    value(PONG, {"PONG", "Pong", false})
    value(PRIVMSG, {"PRIVMSG", "Privmsg", true})
    value(QUIT, {"QUIT", "Quit", true})
    value(SERVER, {"SERVER", "Server", false})
    value(STATS, {"STATS", "Stats", false})
    value(SQUIT, {"SQUIT", "Squit", false})
    value(TRACE, {"TRACE", "Trace", false})
    value(TIME, {"TIME", "Time", false})
    value(TOPIC, {"TOPIC", "Topic", true})
    value(USER, {"USER", "User", true})
    value(VERSION, {"VERSION", "Version", false})
    value(WHO, {"WHO", "Who", false})
    value(WHOIS, {"WHOIS", "Whois", false})
    value(WHOWAS, {"WHOWAS", "Whowas", false})

    @spec matching_value(name :: String.t()) :: tuple() | nil
    def matching_value(name) do
      Enum.find(IRC.Parsers.Message.Commands.values(), &(elem(&1, 0) == name))
    end
  end

  defp check_end(message) do
    if String.ends_with?(message, "\r\n") do
      :ok
    else
      {:error, "Does not end with \\r\\n"}
    end
  end

  defp check_empty(message) do
    if String.length(message) != 2 do
      :ok
    else
      {:error, "Empty"}
    end
  end

  defp check_valid_command(message) do
    command = message |> strip_crlf() |> String.split(" ") |> hd

    matching_command =
      Enum.find(
        IRC.Parsers.Message.Commands.options(),
        fn {_, data} -> elem(data, 0) == command end
      )

    if matching_command != nil do
      {:ok, matching_command}
    else
      escaped_command = escape_crlf(command)
      {:error, "Command \"#{escaped_command}\" not found"}
    end
  end

  defp parse_trailing_param(message, matching) do
    if elem(matching, 2) do
      # The message should have a trailing parameter, so need to find the
      # first instance of ":" and make everything afterward a single parameter.
      case :binary.match(message, ":") do
        {index, _} ->
          {before_trailing, after_trailing} = String.split_at(message, index)

          after_trailing = after_trailing |> strip_crlf() |> String.slice(1, @message_max_length)

          [command | params] =
            before_trailing
            |> String.trim()
            |> String.split(" ")

          params = params ++ [after_trailing]
          {:ok, command, params}

        :nomatch ->
          {:error, "Missing trailing parameter"}
      end
    else
      parts = message |> strip_crlf() |> String.split(" ")
      [command | parameters] = parts
      {:ok, command, parameters}
    end
  end

  @doc """
  Replace the \\r\\n in the string with \\\\\\r\\\\\\n.
  """
  @spec escape_crlf(message :: String.t()) :: String.t()
  def escape_crlf(message) do
    message
    |> String.replace("\r", "\\r")
    |> String.replace("\n", "\\n")
  end

  @doc """
  Remove the trailing \\r\\n in the string.
  """
  @spec strip_crlf(message :: String.t()) :: String.t()
  def strip_crlf(message), do: String.trim_trailing(message, "\r\n")

  @doc """
  Parse a message from the client into a command with parameters,
  and then validate against known commands and parameter lengths.
  """
  @spec parse_message(String.t()) :: tuple()
  def parse_message(message, check \\ :max_length, data \\ %{}) do
    case check do
      # start point
      :max_length ->
        if String.length(message) <= @message_max_length do
          parse_message(message, :terminate)
        else
          {:error, "Too long (max is 512 chars)"}
        end

      :terminate ->
        case check_end(message) do
          :ok -> parse_message(message, :effectively_empty)
          err = {:error, _} -> err
        end

      # validate that the string isn't empty (other than \r\n)
      :effectively_empty ->
        case check_empty(message) do
          :ok -> parse_message(message, :valid)
          err = {:error, _} -> err
        end

      # check that the message contains a recognized command
      :valid ->
        case check_valid_command(message) do
          {:ok, matching_command} ->
            {_, matching} = matching_command
            # the matching command is added to subsequent calls to this function
            parse_message(message, :trailing, %{matching: matching})

          err = {:error, _} ->
            err
        end

      # try to convert any trailing parameters to a single parameter
      :trailing ->
        parse_trailing_param(message, data.matching)
    end
  end
end
