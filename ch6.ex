defmodule ServerProcess do
  def start(module) do
    spawn(fn () ->
      state = module.init
      loop(module, state)
    end)
  end

  def call(pid, request) do
    send(pid, {:call, request, self})
    receive do
      {:response, response} ->
        response
    end
  end

  def cast(pid, request) do
    send(pid, {:cast, request})
    :ok
  end

  defp loop(module, state) do
    receive do
      {:call, request, caller} ->
        {response, new_state} = module.handle_call(request, state)
        send(caller, {:response, response})
        loop(module, new_state)
      {:cast, request} ->
        new_state = module.handle_cast(request, state)
        loop(module, new_state)
    end
  end
end

defmodule KeyValueStore do
  def start, do: ServerProcess.start(KeyValueStore)

  def put(pid, key, val), do: ServerProcess.cast(pid, {:put, key, val})
  def get(pid, key), do: ServerProcess.call(pid, {:get, key})

  def init do
    HashDict.new
  end

  def handle_cast({:put, key, val}, dict), do: HashDict.put(dict, key, val)
  def handle_call({:get, key}, dict), do: {HashDict.get(dict, key), dict}
end

defmodule TodoServer do
  def init, do: TodoList.new

  def start, do: ServerProcess.start(TodoServer)

  def add_entry(pid, entry), do: ServerProcess.cast(pid, {:add_entry, entry})

  def entries(pid, date) do
    ServerProcess.cast(pid, {:entries, self, date})

    receive do
      {:todo_entries, entries} -> entries
    after 5000 ->
      {:error, :timeout}
    end
  end

  def handle_cast({:add_entry, entry}, todo_list) do
    TodoList.add_entry(todo_list, entry)
  end
  def handle_cast({:entries, caller, date}, todo_list) do
    send(caller, {:todo_entries, TodoList.entries(todo_list, date)})
    todo_list
  end
  def handle_cast(_, todo_list), do: todo_list
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
