defmodule Todo.DatabaseWorker do
  use GenServer

  def start(dir), do: GenServer.start(__MODULE__, dir)

  def init(dir) do
    File.mkdir_p(dir)
    {:ok, dir}
  end

  def store(pid, key, val), do: GenServer.cast(pid, {:store, key, val})
  def get(pid, key), do: GenServer.call(pid, {:get, key})

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
end
