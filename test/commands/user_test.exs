defmodule IRC.Commands.User.Test do
  use ExUnit.Case
  alias IRC.Commands.User

  test "mode_to_letters" do
    assert(User.mode_to_letters(6) == "iw")
    assert(User.mode_to_letters(4) == "i")
    assert(User.mode_to_letters(2) == "w")
    assert(User.mode_to_letters(0) == "")
  end
end
