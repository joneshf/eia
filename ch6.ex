defmodule KeyValueStore do
  use GenServer

  def start, do: GenServer.start(KeyValueStore, nil)

  def put(pid, key, val), do: GenServer.cast(pid, {:put, key, val})
  def get(pid, key), do: GenServer.call(pid, {:get, key})

  def init(_state) do
    :timer.send_interval(5000, :cleanup)
    {:ok, HashDict.new}
  end

  def handle_call({:get, key}, _caller, dict) do
    {:reply, HashDict.get(dict, key), dict}
  end

  def handle_cast({:put, key, val}, dict) do
    {:noreply, HashDict.put(dict, key, val)}
  end

  def handle_info(:cleanup, state) do
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end

defmodule TodoServer do
  use GenServer

  def init(_state), do: {:ok, TodoList.new}

  def start, do: GenServer.start(TodoServer, nil)

  def add_entry(pid, entry), do: GenServer.cast(pid, {:add_entry, entry})

  def entries(pid, date) do
    GenServer.cast(pid, {:entries, self, date})

    receive do
      {:todo_entries, entries} -> entries
    after 5000 ->
      {:error, :timeout}
    end
  end

  def handle_cast({:add_entry, entry}, todo_list) do
    {:noreply, TodoList.add_entry(todo_list, entry)}
  end
  def handle_cast({:entries, caller, date}, todo_list) do
    send(caller, {:todo_entries, TodoList.entries(todo_list, date)})
    {:noreply, todo_list}
  end
  def handle_cast(_, todo_list), do: {:noreply, todo_list}
end

defmodule TodoList do
  defstruct auto_id: 1, entries: HashDict.new

  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %TodoList{},
      &add_entry(&2, &1)
    )
  end

  def add_entry(
    %TodoList{entries: entries, auto_id: auto_id} = todo_list,
    entry
  ) do
    entry = Map.put(entry, :id, auto_id)
    new_entries = HashDict.put(entries, auto_id, entry)

    %TodoList{todo_list |
      entries: new_entries,
      auto_id: auto_id + 1
    }
  end

  def entries(%TodoList{entries: entries}, date) do
    entries
    |> Stream.filter(fn({_, entry}) ->
         entry.date == date
       end)

    |> Enum.map(fn({_, entry}) ->
         entry
       end)
  end

  def update_entry(todo_list, %{} = new_entry) do
    update_entry(todo_list, new_entry.id, fn(_) -> new_entry end)
  end

  def update_entry(
    %TodoList{entries: entries} = todo_list,
    entry_id,
    updater_fun
  ) do
    case entries[entry_id] do
      nil -> todo_list

      old_entry ->
        new_entry = updater_fun.(old_entry)
        new_entries = HashDict.put(entries, new_entry.id, new_entry)
        %TodoList{todo_list | entries: new_entries}
    end
  end

  def delete_entry(
    %TodoList{entries: entries} = todo_list,
    entry_id
  ) do
    %TodoList{todo_list | entries: HashDict.delete(entries, entry_id)}
  end
end
