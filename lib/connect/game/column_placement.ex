defmodule Connect.Game.ColumnPlacement do
  def find_placement(state, drop_column) do
    max_index = state[:rows] * state[:columns] - 1
    col_offset = state[:columns] - drop_column - 1
    find_placement_(state, max_index - col_offset)
  end

  defp find_placement_(_state, current_index) when current_index < 0 do
    {:error, :column_full}
  end

  defp find_placement_(state, current_index) when current_index >= 0 do
    current_index_available = Enum.at(state[:board], current_index) == nil

    case current_index_available do
      true -> {:ok, current_index}
      false ->
        next_index = current_index - state[:columns]
        find_placement_(state, next_index)
    end
  end
end
