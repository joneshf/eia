defmodule Todo.PoolSupervisor do
  use Supervisor

  def start_link(dir, size) do
    Supervisor.start_link(__MODULE__, {dir, size})
  end

  def init({dir, size}) do
    processes = for id <- 1..size do
      worker(Todo.DatabaseWorker, [dir, id], id: {:database_worker, id})
    end

    supervise(processes, strategy: :one_for_one)
  end
end
