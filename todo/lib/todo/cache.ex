defmodule Todo.Cache do
  use GenServer
  @reg :todo_cache

  def init(_) do
    {:ok, nil}
  end

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: @reg)
  end

  def server_process(name) do
    Todo.ProcessRegistry.whereis_name({:todo_server, name})
    |> process_server_process(name)
  end

  def handle_call({:server_process, name}, _, state) do
    Todo.ProcessRegistry.whereis_name({:todo_server, name})
    |> process_whereis_name(name, state)
  end

  defp process_whereis_name(:undefined, name, state) do
    {:ok, pid} = Todo.ServerSupervisor.start_child(name)
    {:reply, pid, state}
  end
  defp process_whereis_name(pid, _name, state), do: {:reply, pid, state}

  defp process_server_process(:undefined, name) do
    GenServer.call(@reg, {:server_process, name})
  end
  defp process_server_process(pid, _name), do: pid
end
