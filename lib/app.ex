defmodule IRC.Application do
  use Application
  require Logger

  @default_port "6697"

  @impl true
  def start(_type, _args) do
    Logger.info("Starting supervisor")

    port = String.to_integer(System.get_env("PORT") || @default_port)

    children = [
      {DynamicSupervisor, name: IRC.DynamicSupervisor, strategy: :one_for_one},
      Supervisor.child_spec({Task, fn -> IRC.Listener.accept(port) end}, restart: :permanent),
      IRC.Server
    ]

    opts = [strategy: :one_for_one, name: IRC.MainSupervisor]

    Supervisor.start_link(children, opts)
  end
end
