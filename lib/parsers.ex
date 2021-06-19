defmodule IRC.Parsers.Message do
  use EnumType

  @message_max_length 512

  # {
  #   Enum Name,
  #   {
  #     String value
  #     min. # param,
  #     max. # params (or -1),
  #     if last param is multi-word
  #   }
  # }
  defenum Commands do
    value(ADMIN, {"ADMIN", 0, false})
    # value(CONNECT, {"CONNECT", 0, false})
    # value(ERROR, {"ERROR", 0, false})
    value(INFO, {"INFO", 0, false})
    value(INVITE, {"INVITE", 2, false})
    value(JOIN, {"JOIN", 1, false})
    value(KICK, {"KICK", 2, false})
    value(KILL, {"KILL", 2, false})
    # value(LINKS, {"LINKS", 0, false})
    value(LIST, {"LIST", 1, false})
    value(MODE, {"MODE", 1, false})
    value(NAMES, {"NAMES", 1, false})
    value(NICK, {"NICK", 1, false})
    value(NOTICE, {"NOTICE", 2, true})
    value(OPER, {"OPER", 2, false})
    value(PART, {"PART", 1, false})
    value(PASS, {"PASS", 1, false})
    # value(PING, {"PING", 0, false})
    # value(PONG, {"PONG", 0, false})
    value(PRIVMSG, {"PRIVMSG", 2, true})
    value(QUIT, {"QUIT", 0, true})
    # value(SERVER, {"SERVER", 0, false})
    # value(STATS, {"STATS", 0, false})
    # value(SQUIT, {"SQUIT", 0, false})
    # value(TRACE, {"TRACE", 0, false})
    value(TIME, {"TIME", 0, false})
    value(TOPIC, {"TOPIC", 1, true})
    value(USER, {"USER", 4, true})
    value(VERSION, {"VERSION", 0, false})
    value(WHO, {"WHO", 0, false})
    value(WHOIS, {"WHOIS", 1, false})
    # value(WHOWAS, {"WHOWAS", 0, false})
  end

  @doc """
  Replace the \\r\\n in the string with \\\\\\r\\\\\\n.
  """
  @spec strip_crlf(String.t()) :: String.t()
  def strip_crlf(message) do
    message
    |> String.replace("\r", "\\r")
    |> String.replace("\n", "\\n")
  end

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
          {:error, "Too long (max 512 chars)"}
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
        case parse_trailing_param(message, data.matching) do
          {:ok, command, parameters} ->
            data = Map.put(data, :command, command)
            data = Map.put(data, :parameters, parameters)
            parse_message(message, :param_length, data)

          err = {:error, _} ->
            err
        end

      # validate the command has the correct number of parameters
      :param_length ->
        check_parameter_count(data.command, data.parameters, data.matching)
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
    command = hd(String.split(message, " "))

    matching_command =
      Enum.find(
        IRC.Parsers.Message.Commands.options(),
        fn {_, data} -> elem(data, 0) == command end
      )

    if matching_command != nil do
      {:ok, matching_command}
    else
      {:error, "Command \"#{command}\" not found"}
    end
  end

  defp parse_trailing_param(message, matching) do
    if elem(matching, 2) do
      # The message should have a trailing parameter, so need to find the
      # first instance of ":" and make everything afterward a single parameter.
      case :binary.match(message, ":") do
        {index, _} ->
          {before_trailing, after_trailing} = String.split_at(message, index)

          after_trailing =
            after_trailing |> String.trim_trailing("\r\n") |> String.slice(1, @message_max_length)

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
      parts = message |> String.trim_trailing("\r\n") |> String.split(" ")
      [command | parameters] = parts
      {:ok, command, parameters}
    end
  end

  defp check_parameter_count(command, parameters, matching) do
    max_params = elem(matching, 1)

    if max_params != -1 and length(parameters) > max_params do
      {:error, "Need more parameters: have #{length(parameters)}, need <= #{max_params}"}
    else
      {:ok, command, parameters}
    end
  end
end
