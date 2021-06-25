defmodule IRC.Parsers.Message.Test do
  use ExUnit.Case
  alias IRC.Parsers.Message

  describe "command parsing" do
    test "too long" do
      {:error, _} = Message.parse_message(String.duplicate("a", 600))
    end

    test "requires ending with \\r\\n" do
      {:error, _} = Message.parse_message("NICK bob")
    end

    test "requires not empty" do
      {:error, _} = Message.parse_message("")
    end

    test "requires valid command" do
      {:error, _} = Message.parse_message("HELLO WORLD\r\n")
    end

    test "works for simple use-cases" do
      {:ok, "NICK", ["bob"]} = Message.parse_message("NICK bob\r\n")
    end

    test "parses multi-word parameters with colons" do
      {:error, _} = Message.parse_message("PRIVMSG #hello a b c\r\n")

      {:ok, "PRIVMSG", ["#hello", "a b c"]} = Message.parse_message("PRIVMSG #hello :a b c\r\n")
    end
  end

  describe "command enum" do
    alias IRC.Parsers.Message.Commands

    test "can find matching" do
      assert(Commands.matching_value("NICK") == Commands.NICK.value())
      assert(Commands.matching_value("abcdefg") == nil)
    end
  end
end
