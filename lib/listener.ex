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
      DynamicSupervisor.start_child(IRC.DynamicSupervisor, {IRC.ClientConnection, {client}})

    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end
end
