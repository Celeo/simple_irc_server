defmodule IRC.Server do
  use GenServer
  require Logger

  @impl true
  def init(state) do
    {:ok, state}
  end

  def start_link(state) do
    Logger.info("Starting server")
    GenServer.start_link(__MODULE__, state, name: IRC.Server)
  end
end
