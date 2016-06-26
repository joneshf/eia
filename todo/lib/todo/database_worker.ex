defmodule Todo.DatabaseWorker do
  use GenServer

  def start_link(dir, id), do: GenServer.start_link(__MODULE__, dir, name: via(id))

  def init(dir) do
    File.mkdir_p(dir)
    {:ok, dir}
  end

  def store(id, key, val), do: GenServer.cast(via(id), {:store, key, val})
  def get(id, key), do: GenServer.call(via(id), {:get, key})

  def handle_call({:get, key}, caller, dir) do
    spawn(fn () ->
      val = process(File.read(Path.join([dir, key])))
      GenServer.reply(caller, val)
    end)
    {:noreply, dir}
  end

  def handle_cast({:store, key, val}, dir) do
    spawn(fn () ->
      :ok = File.write(Path.join([dir, key]), :erlang.term_to_binary(val))
    end)
    {:noreply, dir}
  end

  defp process({:ok, binary}), do: :erlang.binary_to_term(binary)
  defp process({:error, _}), do: nil

  defp via(id) do
    {:via, Todo.ProcessRegistry, {:database_worker, id}}
  end
end
