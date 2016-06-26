defmodule Todo.ProcessRegistry do
  use GenServer
  @reg :todo_process_registry

  def init(_) do
    {:ok, HashDict.new}
  end

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: @reg)
  end

  def register_name(name, pid), do: GenServer.call(@reg, {:register_name, name, pid})

  def unregister_name(name), do: GenServer.cast(@reg, {:unregister_name, name})

  def whereis_name(name), do: GenServer.call(@reg, {:whereis_name, name})

  def send(name, msg), do: GenServer.cast(@reg, {:send, name, msg})

  def handle_call({:register_name, name, pid}, _caller, dict) do
    process_register(HashDict.get(dict, name), pid, name, dict)
  end
  def handle_call({:send, name, msg}, _caller, dict) do
    process_send(whereis_name(name), name, msg, dict)
  end
  def handle_call({:whereis_name, name}, _caller, dict) do
    {:reply, HashDict.get(dict, name, :undefined), dict}
  end

  def handle_cast({:unregister_name, name}, dict) do
    {:noreply, HashDict.delete(dict, name)}
  end

  def handle_info({:DOWN, _, :process, pid, _}, dict) do
    {:noreply, deregister_pid(dict, pid)}
  end

  defp deregister_pid(dict, pid) do
    HashDict.to_list(dict)
    |> Enum.reject(fn ({_name, ^pid}) -> true; _ -> false end)
    |> Enum.reduce(HashDict.new, &insert/2)
  end

  defp insert({key, val}, dict) do
    HashDict.put(dict, key, val)
  end

  defp process_register(nil, pid, name, dict) do
    Process.monitor(pid)
    {:reply, :yes, HashDict.put(dict, name, pid)}
  end
  defp process_register(_, _pid, _name, dict) do
    {:reply, :no, dict}
  end

  defp process_send(:undefined, name, msg, dict) do
    {:reply, {:badarg, {name, msg}}, dict}
  end
  defp process_send(pid, _name, msg, dict) do
    Kernel.send(pid, msg)
    {:reply, pid, dict}
  end
end
