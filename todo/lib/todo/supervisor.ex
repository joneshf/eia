defmodule Todo.Supervisor do
  use Supervisor

  def init(_) do
    process = [
      worker(Todo.ProcessRegistry, []),
      supervisor(Todo.Database, [Path.join([".", "persist"])]),
      supervisor(Todo.ServerSupervisor, []),
      worker(Todo.Cache, []),
    ]
    supervise(process, strategy: :one_for_one)
  end

  def start_link do
    Supervisor.start_link(__MODULE__, nil)
  end
end
