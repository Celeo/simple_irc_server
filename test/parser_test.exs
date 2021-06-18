defmodule IRC.Parsers.Message.Test do
  use ExUnit.Case

  test "too long" do
    {:error, _} = IRC.Parsers.Message.parse_message(String.duplicate("a", 600))
  end

  test "requires ending with \\r\\n" do
    {:error, _} = IRC.Parsers.Message.parse_message("NICK bob")
  end

  test "requires not empty" do
    {:error, _} = IRC.Parsers.Message.parse_message("")
  end

  test "requires valid command" do
    {:error, _} = IRC.Parsers.Message.parse_message("HELLO WORLD\r\n")
  end

  test "works for simple use-cases" do
    {:ok, "NICK", ["bob"]} = IRC.Parsers.Message.parse_message("NICK bob\r\n")
  end

  test "parses multi-word parameters with colons" do
    {:error, _} = IRC.Parsers.Message.parse_message("PRIVMSG #hello a b c\r\n")

    {:ok, "PRIVMSG", ["#hello", "a b c"]} =
      IRC.Parsers.Message.parse_message("PRIVMSG #hello :a b c\r\n")
  end

  test "determines min/max parameters length" do
    {:error, _} = IRC.Parsers.Message.parse_message("NICK\r\n")
    {:ok, _, _} = IRC.Parsers.Message.parse_message("NICK a\r\n")
    {:error, _} = IRC.Parsers.Message.parse_message("NICK a b\r\n")
  end
end