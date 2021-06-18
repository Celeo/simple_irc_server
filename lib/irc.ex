defmodule IRC.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Starting supervisor")

    port = String.to_integer(System.get_env("PORT") || "4040")

    children = [
      {Task.Supervisor, name: IRC.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> IRC.Listener.accept(port) end},
        restart: :permanent
      )
    ]

    opts = [strategy: :one_for_one, name: IRC.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule IRC.Listener do
  require Logger

  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(IRC.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    socket
    |> read_line()
    |> prepend_response()
    |> write_line(socket)

    serve(socket)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp prepend_response(line) do
    "Received: #{line}"
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end
end
