defmodule SimpleServer.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting application")
    SimpleServer.Supervisor.start_link(name: SimpleServer.Supervisor)
  end
end

defmodule SimpleServer.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      # TODO
    ]

    Logger.info("Starting supervisor")
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule SimpleServer.Listener do
  require Logger

  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Logger.info("Got connection")
    serve(client)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    socket
    |> read_line()
    |> write_line(socket)

    serve(socket)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end
end
