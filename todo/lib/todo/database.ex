defmodule Todo.Database do
  @pool_size 3

  def start_link(dir), do: Todo.PoolSupervisor.start_link(dir, @pool_size)

  def store(key, val), do: Todo.DatabaseWorker.store(get_worker(key), key, val)

  def get(key), do: Todo.DatabaseWorker.get(get_worker(key), key)

  defp get_worker(key), do: :erlang.phash2(key, @pool_size) + 1
end
