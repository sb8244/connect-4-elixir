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
    blank_board = Tuple.duplicate(nil, rows * columns)
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
          board: put_elem(state[:board], place_index, current_player),
          turn: state[:turn] + 1
        })

        {:reply, {:ok, new_state}, new_state}
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
    current_index_available = elem(state[:board], current_index) == nil

    case current_index_available do
      true -> {:ok, current_index}
      false ->
        next_index = current_index - state[:columns]
        find_placement_(state, next_index)
    end
  end
end
