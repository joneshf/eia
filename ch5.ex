defmodule Calculator do
  def start do
    spawn(fn () -> loop(0) end)
  end

  def value(pid) do
    send(pid, {:value, self})
    receive do
      {:ok, value} ->
        value
    end
  end

  def add(pid, value), do: send(pid, {:add, value})
  def sub(pid, value), do: send(pid, {:sub, value})
  def mul(pid, value), do: send(pid, {:mul, value})
  def div(pid, value), do: send(pid, {:div, value})

  defp loop(state) do
    new_state = receive do
      msg ->
        process(state, msg)
    end
    loop(new_state)
  end

  defp process(state, {:value, pid}) do
    send(pid, {:ok, state})
    state
  end
  defp process(state, {:add, value}), do: state + value
  defp process(state, {:sub, value}), do: state - value
  defp process(state, {:mul, value}), do: state * value
  defp process(state, {:div, value}), do: state / value
end
