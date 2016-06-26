defmodule Todo.ServerSupervisor do
  use Supervisor
  @reg :todo_server_supervisor

  def start_link, do: Supervisor.start_link(__MODULE__, nil, name: @reg)

  def start_child(name), do: Supervisor.start_child(@reg, [name])

  def init(_) do
    processes = [worker(Todo.Server, [])]
    supervise(processes, strategy: :simple_one_for_one)
  end
end
