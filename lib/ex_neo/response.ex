defmodule ExNeo.Response do
  @moduledoc """
  Defines the structure that holds the response from the Neo4j
  rest server.
  """

  def map_json(%{"columns" => columns, "data" => data})
      when is_list(columns) and is_list(data) do
    Enum.map(data, fn %{"row" => row} ->
      zip_data(columns, row)
    end)
  end

  defp zip_data(columns, row, map \\ %{})
  defp zip_data([], [], map), do: map
  defp zip_data([column|column_tail], [row|row_tail], map) do
    map = Map.put(map, column, row)
    zip_data(column_tail, row_tail, map)
  end

end

