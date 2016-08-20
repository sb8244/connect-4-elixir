defmodule Connect.Game.Server do
  use GenServer

  def start_link(name, args) do
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def get_state(server) do
    GenServer.call(server, {:state})
  end

  def make_move(server, column) do
    GenServer.call(server, {:make_move, column})
  end

  def check_winner(server) do
    GenServer.call(server, {:check_winner})
  end

  # Server Callbacks
  def init(%{rows: rows, columns: columns, win_size: win_size}) do
    blank_board = List.duplicate(nil, rows * columns)
    {:ok, %{board: blank_board, turn: 0, rows: rows, columns: columns, win_size: win_size}}
  end

  def handle_call({:state}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:priv_set_board, board}, _from, state) do
    new_state = Map.merge(state, %{ board: board })
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call({:make_move, column}, _from, state) do
    case find_placement(state, column) do
      {:ok, place_index} ->
        current_player = rem(state[:turn], 2) + 1
        new_state = Map.merge(state, %{
          board: List.replace_at(state[:board], place_index, current_player),
          turn: state[:turn] + 1
        })
        {:reply, {:ok, new_state}, new_state}
      {:error, _} = err ->
        {:reply, err, state}
    end
  end

  def handle_call({:check_winner}, _from, state) do
    winner = check_for_win_h(state) || check_for_win_v(state) || check_for_win_d(state)

    case winner do
      nil -> {:reply, {:ok, state}, state}
      winner ->
        {:reply, {:ok, :win, winner, state}, state}
    end
  end

  defp find_placement(state, drop_column) do
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

  defp check_for_win_h(state) do
    rows = group_into_rows(state[:board], state[:columns])
    find_win_in_sets(rows, state[:win_size])
  end

  defp check_for_win_v(state) do
    cols = group_into_columns(state[:board], state[:columns])
    find_win_in_sets(cols, state[:win_size])
  end

  defp check_for_win_d(state) do
    diags = group_into_diags(state[:board], state[:columns])
    find_win_in_sets(diags, state[:win_size])
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
