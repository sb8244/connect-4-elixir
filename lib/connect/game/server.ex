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

  def make_move(server, row, column) do
    GenServer.call(server, {:place_piece, row, column})
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
    cond do
      column >= 0 && column < state[:columns] ->
        case Connect.Game.ColumnPlacement.find_placement(state, column) do
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
      true ->
        {:reply, {:error, :invalid_move}, state}
    end
  end

  def handle_call({:place_piece, row, column}, _from, state) do
    cond do
      row >= 0 && row < state[:rows] && column >= 0 && column < state[:columns] ->
        place_index = row * state[:columns] + column

        case Enum.at(state[:board], place_index) do
          nil ->
            current_player = rem(state[:turn], 2) + 1
            new_state = Map.merge(state, %{
              board: List.replace_at(state[:board], place_index, current_player),
              turn: state[:turn] + 1
            })
            {:reply, {:ok, new_state}, new_state}
          _ ->
            {:reply, {:error, :invalid_move}, state}
        end
      true ->
        {:reply, {:error, :invalid_move}, state}
    end
  end

  def handle_call({:check_winner}, _from, state) do
    winner = Connect.Game.WinCheck.check_winner(state[:board], state[:columns], state[:win_size])

    case winner do
      nil -> {:reply, {:ok, state}, state}
      winner ->
        {:reply, {:ok, :win, winner, state}, state}
    end
  end
end
