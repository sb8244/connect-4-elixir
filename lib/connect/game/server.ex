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

  # Server Callbacks
  def init(%{rows: rows, columns: columns, win_size: win_size}) do
    blank_board = List.duplicate(nil, rows * columns)
    {:ok, %{board: blank_board, turn: 0, rows: rows, columns: columns, win_size: win_size}}
  end

  def handle_call({:state}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:make_move, column}, _from, state) do
    case find_placement(state, column) do
      {:ok, place_index} ->
        current_player = rem(state[:turn], 2) + 1
        new_state = Map.merge(state, %{
          board: List.replace_at(state[:board], place_index, current_player),
          turn: state[:turn] + 1
        })

        winner = check_for_win_h(new_state) || check_for_win_v(new_state) || check_for_win_d(new_state)

        case winner do
          nil -> {:reply, {:ok, new_state}, new_state}
          winner ->
            {:reply, {:ok, :win, winner, new_state}, new_state}
        end
      {:error, _} = err ->
        {:reply, err, state}
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
end

_board = [
  0, 1, 2, 3,
  4, 5, 6, 7,
  8, 9, 10, 11
]

[[0], [1, 4], [2, 5, 8], [3, 6, 9], [7, 10], [11]]

[
  1, 2, 1, 2,
  2, 1, 2, 1,
  1, 2, 2, 2
]

[
  0,  1,  2,  3,  4,  5,  6,
  7,  8,  9,  10, 11, 12, 13,
  14, 15, 16, 17, 18, 19, 20,
  21, 22, 23, 24, 25, 26, 27,
  28, 29, 30, 31, 32, 33, 34
]


[
  [0], [1, 7], [2, 8, 14], [3, 9, 15, 21], [4, 10, 16, 22, 28], [5, 11, 17, 23, 29],
  [6, 12, 18, 24, 30], [13, 19, 25, 31], [20, 26, 32], [27, 33], [34]
]
