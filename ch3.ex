defmodule RecursionPractice do
  def list_len([]), do: 0
  def list_len([_|t]), do: 1 + list_len(t)

  def range(from, to) when from < to, do: [from|range(from + 1, to)]
  def range(_, _), do: []

  def positive([]), do: []
  def positive([h|t]) when h > 0, do: [h|positive(t)]
  def positive([_|t]), do: positive(t)
end

defmodule TailRecursionPractice do
  def list_len(xs), do: list_len(xs, 0)

  defp list_len([], acc), do: acc
  defp list_len([_|t], acc), do: list_len(t, acc + 1)

  def range(from, to), do: Enum.reverse(range(from, to, []))

  defp range(from, to, acc) when from < to, do: range(from + 1, to, [from|acc])
  defp range(_, _, acc), do: acc

  def positive(xs), do: Enum.reverse(positive(xs, []))

  defp positive([], acc), do: acc
  defp positive([h|t], acc) when h > 0, do: positive(t, [h|acc])
  defp positive([_|t], acc), do: positive(t, acc)
end
