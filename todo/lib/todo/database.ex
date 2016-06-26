defmodule Todo.Database do
  use GenServer

  def start(dir), do: GenServer.start(__MODULE__, dir, name: name)

  def init(dir) do
    File.mkdir_p(dir)
    {:ok, pid0} = Todo.DatabaseWorker.start(dir)
    {:ok, pid1} = Todo.DatabaseWorker.start(dir)
    {:ok, pid2} = Todo.DatabaseWorker.start(dir)
    {:ok, {{pid0, pid1, pid2}, dir}}
  end

  def store(key, val) do
    worker = get_worker(:erlang.phash2(key, 3))
    Todo.DatabaseWorker.store(worker, key, val)
  end
  def get(key) do
    worker = get_worker(:erlang.phash2(key, 3))
    Todo.DatabaseWorker.get(worker, key)
  end

  def handle_call({:get_worker, 0}, _caller, state = {{worker, _, _}, dir}) do
    {:reply, worker, state}
  end
  def handle_call({:get_worker, 1}, _caller, state = {{_, worker, _}, dir}) do
    {:reply, worker, state}
  end
  def handle_call({:get_worker, 2}, _caller, state = {{_, _, worker}, dir}) do
    {:reply, worker, state}
  end

  defp name, do: :database_server
  defp get_worker(n), do: GenServer.call(name, {:get_worker, n})
end
