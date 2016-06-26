defmodule Todo.Cache do
  use GenServer

  def init(_) do
    Todo.Database.start(Path.join([".", "persist"]))
    {:ok, HashDict.new}
  end

  def start do
    GenServer.start(__MODULE__, nil)
  end

  def server_process(pid, name), do: GenServer.call(pid, {:server_process, name})

  def handle_call({:server_process, name}, _, servers) do
    process(name, servers, HashDict.fetch(servers, name))
  end

  defp process(_name, servers, {:ok, server}), do: {:reply, server, servers}
  defp process(name, servers, :error) do
    {:ok, server} = Todo.Server.start(name)
    {:reply, server, HashDict.put(servers, name, server)}
  end
end
