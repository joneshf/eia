defmodule Todo.Server do
  use GenServer

  def init(name), do: {:ok, {name, Todo.Database.get(name) || Todo.List.new}}

  def start(name), do: GenServer.start(Todo.Server, name)

  def add_entry(pid, entry), do: GenServer.cast(pid, {:add_entry, entry})

  def entries(pid, date) do
    GenServer.cast(pid, {:entries, self, date})

    receive do
      {:todo_entries, entries} -> entries
    after 5000 ->
      {:error, :timeout}
    end
  end

  def handle_cast({:add_entry, entry}, {name, todo_list}) do
    new_list = Todo.List.add_entry(todo_list, entry)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}}
  end
  def handle_cast({:entries, caller, date}, state = {name, todo_list}) do
    send(caller, {:todo_entries, Todo.List.entries(todo_list, date)})
    {:noreply, state}
  end
  def handle_cast(_, state), do: {:noreply, state}
end
