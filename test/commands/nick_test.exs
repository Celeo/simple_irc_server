defmodule IRC.Commands.Nick.Test do
  use ExUnit.Case
  alias IRC.Commands.Nick

  test "valid_username" do
    :ok = Nick.valid_username("Celeo")
    {:error, 431, _} = Nick.valid_username("")
    {:error, 432, _} = Nick.valid_username("1234567890")
  end
end
