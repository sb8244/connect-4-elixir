defmodule Connect.Game.WinCheck do
  def check_winner(board, columns, win_size) do
    check_for_win_h(board, columns, win_size) ||
    check_for_win_v(board, columns, win_size) ||
    check_for_win_d(board, columns, win_size)
  end

  # Helper methods

  @doc """
    Check for wins that happens in a horizontal row.

    ## Examples

        iex> Connect.Game.WinCheck.check_for_win_h([2, nil, 2, 1, 1, nil], 3, 2)
        1

        iex> Connect.Game.WinCheck.check_for_win_h([2, 2, 2, 1, 1, nil], 3, 3)
        2

        iex> Connect.Game.WinCheck.check_for_win_h([nil, nil, nil], 3, 1)
        nil
  """
  def check_for_win_h(board, columns, win_size) do
    rows = group_into_rows(board, columns)
    find_win_in_sets(rows, win_size)
  end

  @doc """
    Check for wins that happens in a vertical column.

    ## Examples

        iex> Connect.Game.WinCheck.check_for_win_v([nil, 2, nil, 1, nil, 1], 2, 2)
        1

        iex> Connect.Game.WinCheck.check_for_win_v([nil, 1, nil, 2, nil, 1], 2, 2)
        nil
  """
  def check_for_win_v(board, columns, win_size) do
    cols = group_into_columns(board, columns)
    find_win_in_sets(cols, win_size)
  end

  @doc """
    Check for wins that happens in 4 different diagonals.
    A win might be left-right-up left-right-down right-left-up right-left-down

    ## Examples

        iex> Connect.Game.WinCheck.check_for_win_d([nil, nil, 1, nil, 1, 2, 1, 2, 2], 3, 3)
        1

        iex> Connect.Game.WinCheck.check_for_win_d([2, nil, nil, 2], 2, 2)
        2

        iex> Connect.Game.WinCheck.check_for_win_d([2, nil, nil, 2], 2, 3)
        nil
  """
  def check_for_win_d(board, columns, win_size) do
    diags = group_into_diags(board, columns)
    find_win_in_sets(diags, win_size)
  end

  defp find_win_in_sets(sets, win_size) do
    Enum.find_value(sets, fn(set) ->
      possible_wins = Enum.chunk(set, win_size, 1)
      win = Enum.find(possible_wins, fn(combo) ->
        dedup = Enum.dedup(combo)
        dedup != [nil] && Enum.count(dedup) == 1
      end)
      case win do
        nil -> false
        _ -> Enum.at(win, 0)
      end
    end)
  end

  defp group_into_rows(board, col_size) do
    Enum.chunk(board, col_size)
  end

  defp group_into_columns(board, col_size) do
    indices = 0..Enum.count(board)-1
    collected = Enum.reduce(indices, %{}, fn(index, collected) ->
      grouping = rem(index, col_size)
      grouping_list = collected[grouping] || []
      new_grouping_list = grouping_list ++ [Enum.at(board, index)]
      Map.put(collected, grouping, new_grouping_list)
    end)
    Map.values(collected)
  end

  defp group_into_diags(board, col_size) do
    indices = 0..Enum.count(board)-1
    rows = group_into_rows(indices, col_size)
    cols = group_into_columns(indices, col_size)

    left_right_col_diags = Enum.reduce(hd(cols), [], fn(start_index, acc) ->
      diag_indices = step_down_to_0([], start_index, col_size - 1, Enum.count(acc) + 1)
      diag_values = Enum.map(diag_indices, fn(index) -> Enum.at(board, index) end)
      [diag_values | acc]
    end)

    left_right_row_diags = Enum.reduce(Enum.at(rows, -1), [], fn(start_index, acc) ->
      diag_indices = step_down_to_0([], start_index, col_size - 1, col_size - Enum.count(acc))
      diag_values = Enum.map(diag_indices, fn(index) -> Enum.at(board, index) end)
      [diag_values | acc]
    end)

    right_left_col_diags = Enum.reduce(Enum.at(cols, -1), [], fn(start_index, acc) ->
      diag_indices = step_down_to_0([], start_index, col_size + 1, Enum.count(acc) + 1)
      diag_values = Enum.map(diag_indices, fn(index) -> Enum.at(board, index) end)
      [diag_values | acc]
    end)

    right_left_row_diags = Enum.reduce(Enum.at(rows, -1), [], fn(start_index, acc) ->
      diag_indices = step_down_to_0([], start_index, col_size + 1, col_size - Enum.count(acc))
      diag_values = Enum.map(diag_indices, fn(index) -> Enum.at(board, index) end)
      [diag_values | acc]
    end)

    left_right_col_diags ++ left_right_row_diags ++ right_left_row_diags ++ right_left_col_diags
  end

  defp step_down_to_0(list, curr, _step, _max_length) when curr < 0 do
    list
  end

  defp step_down_to_0(list, curr, step, max_length) do
    cond do
      Enum.count(list) == max_length -> list
      Enum.count(list) < max_length ->
        step_down_to_0([curr | list], curr - step, step, max_length)
    end
  end
end
