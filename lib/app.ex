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

defmodule IRC.Listener do
  require Logger

  @listen_args [:binary, packet: :line, active: true, reuseaddr: true]

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, @listen_args)
    Logger.info("Starting listener on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, pid} =
      DynamicSupervisor.start_child(IRC.DynamicSupervisor, {IRC.ClientConnection, client})

    :ok = :gen_tcp.controlling_process(client, pid)
    GenServer.call(pid, {:set_pid, pid})
    loop_acceptor(socket)
  end
end
