defmodule IRC.Models.Test do
  use ExUnit.Case
  alias IRC.Models

  describe "Errors" do
    test "lookup" do
      assert(Models.Errors.lookup(:RPL_TRACELINK) == 200)
      assert(Models.Errors.lookup(:not_real) == nil)
    end
  end
end
