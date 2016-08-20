defmodule Connect.Game.ServerTest do
  use ExUnit.Case, async: true

  setup context do
    {:ok, game} = Connect.Game.Server.start_link(context.test, %{rows: 2, columns: 3, win_size: 3})
    {:ok, connect_4} = Connect.Game.Server.start_link(String.to_atom(to_string(context.test) <> "connect_4"), %{rows: 6, columns: 7, win_size: 4})
    {:ok, game: game, connect_4: connect_4}
  end

  describe "call state" do
    test "an empty board is provided", %{game: game, connect_4: connect_4} do
      assert Connect.Game.Server.get_state(game) == %{turn: 0, board: {nil, nil, nil, nil, nil, nil}, rows: 2, columns: 3, win_size: 3}
      assert Connect.Game.Server.get_state(connect_4) == %{turn: 0, board: Tuple.duplicate(nil, 42), rows: 6, columns: 7, win_size: 4}
    end
  end

  describe "call make_move" do
    test "valid moves affect the state", %{game: game} do
      assert Connect.Game.Server.make_move(game, 0) == {:ok, %{turn: 1, board: {nil, nil, nil, 1, nil, nil}, rows: 2, columns: 3, win_size: 3}}
      assert Connect.Game.Server.make_move(game, 1) == {:ok, %{turn: 2, board: {nil, nil, nil, 1, 2, nil}, rows: 2, columns: 3, win_size: 3}}
      assert Connect.Game.Server.make_move(game, 0) == {:ok, %{turn: 3, board: {1, nil, nil, 1, 2, nil}, rows: 2, columns: 3, win_size: 3}}
      assert Connect.Game.Server.make_move(game, 2) == {:ok, %{turn: 4, board: {1, nil, nil, 1, 2, 2}, rows: 2, columns: 3, win_size: 3}}
      assert Connect.Game.Server.make_move(game, 2) == {:ok, %{turn: 5, board: {1, nil, 1, 1, 2, 2}, rows: 2, columns: 3, win_size: 3}}
      assert Connect.Game.Server.make_move(game, 1) == {:ok, %{turn: 6, board: {1, 2, 1, 1, 2, 2}, rows: 2, columns: 3, win_size: 3}}
    end

    test "columns can become full and will error without affecting game state", %{game: game} do
      assert Connect.Game.Server.make_move(game, 0) == {:ok, %{turn: 1, board: {nil, nil, nil, 1, nil, nil}, rows: 2, columns: 3, win_size: 3}}
      assert Connect.Game.Server.make_move(game, 0) == {:ok, %{turn: 2, board: {2, nil, nil, 1, nil, nil}, rows: 2, columns: 3, win_size: 3}}
      assert Connect.Game.Server.make_move(game, 0) == {:error, :column_full}
      assert Connect.Game.Server.get_state(game) == %{turn: 2, board: {2, nil, nil, 1, nil, nil}, rows: 2, columns: 3, win_size: 3}
    end
  end
end
