defmodule Connect.Game.ServerTest do
  use ExUnit.Case, async: true

  setup context do
    {:ok, game} = Connect.Game.Server.start_link(context.test, %{rows: 2, columns: 3, win_size: 3})
    {:ok, diag_simple} = Connect.Game.Server.start_link(String.to_atom(to_string(context.test) <> "diag_simple"), %{rows: 3, columns: 3, win_size: 2})
    {:ok, connect_4} = Connect.Game.Server.start_link(String.to_atom(to_string(context.test) <> "connect_4"), %{rows: 6, columns: 7, win_size: 4})
    {:ok, game: game, connect_4: connect_4, diag_simple: diag_simple}
  end

  describe "call state" do
    test "an empty board is provided", %{game: game, connect_4: connect_4} do
      assert Connect.Game.Server.get_state(game) == %{turn: 0, board: [nil, nil, nil, nil, nil, nil], rows: 2, columns: 3, win_size: 3}
      assert Connect.Game.Server.get_state(connect_4) == %{turn: 0, board: List.duplicate(nil, 42), rows: 6, columns: 7, win_size: 4}
    end
  end

  describe "call make_move" do
    test "valid moves affect the state", %{game: game} do
      assert Connect.Game.Server.make_move(game, 0) == {:ok, %{turn: 1, board: [nil, nil, nil, 1, nil, nil], rows: 2, columns: 3, win_size: 3}}
      assert Connect.Game.Server.make_move(game, 1) == {:ok, %{turn: 2, board: [nil, nil, nil, 1, 2, nil], rows: 2, columns: 3, win_size: 3}}
      assert Connect.Game.Server.make_move(game, 0) == {:ok, %{turn: 3, board: [1, nil, nil, 1, 2, nil], rows: 2, columns: 3, win_size: 3}}
      assert Connect.Game.Server.make_move(game, 2) == {:ok, %{turn: 4, board: [1, nil, nil, 1, 2, 2], rows: 2, columns: 3, win_size: 3}}
      assert Connect.Game.Server.make_move(game, 2) == {:ok, %{turn: 5, board: [1, nil, 1, 1, 2, 2], rows: 2, columns: 3, win_size: 3}}
      assert Connect.Game.Server.make_move(game, 1) == {:ok, %{turn: 6, board: [1, 2, 1, 1, 2, 2], rows: 2, columns: 3, win_size: 3}}
    end

    test "columns can become full and will error without affecting game state", %{game: game} do
      assert Connect.Game.Server.make_move(game, 0) == {:ok, %{turn: 1, board: [nil, nil, nil, 1, nil, nil], rows: 2, columns: 3, win_size: 3}}
      assert Connect.Game.Server.make_move(game, 0) == {:ok, %{turn: 2, board: [2, nil, nil, 1, nil, nil], rows: 2, columns: 3, win_size: 3}}
      assert Connect.Game.Server.make_move(game, 0) == {:error, :column_full}
      assert Connect.Game.Server.get_state(game) == %{turn: 2, board: [2, nil, nil, 1, nil, nil], rows: 2, columns: 3, win_size: 3}
    end
  end

  describe "call check_winner" do
    test "a horizontal win returns a new message type", %{game: game} do
      Connect.Game.Server.make_move(game, 0)
      Connect.Game.Server.make_move(game, 0)
      Connect.Game.Server.make_move(game, 1)
      Connect.Game.Server.make_move(game, 1)
      assert Connect.Game.Server.make_move(game, 2) == {:ok, %{turn: 5, board: [2, 2, nil, 1, 1, 1], rows: 2, columns: 3, win_size: 3}}
      assert {:ok, :win, 1, _board} = Connect.Game.Server.check_winner(game)
    end

    test "a vertical win returns a new message type", %{connect_4: game} do
      Connect.Game.Server.make_move(game, 3)
      Connect.Game.Server.make_move(game, 1)
      Connect.Game.Server.make_move(game, 3)
      Connect.Game.Server.make_move(game, 1)
      Connect.Game.Server.make_move(game, 3)
      Connect.Game.Server.make_move(game, 1)
      assert {:ok, %{turn: 7, board: final_board, rows: 6, columns: 7, win_size: 4}} = Connect.Game.Server.make_move(game, 3)
      assert final_board == [
        nil, nil, nil, nil, nil, nil, nil,
        nil, nil, nil, nil, nil, nil, nil,
        nil, nil, nil, 1, nil, nil, nil,
        nil, 2, nil, 1, nil, nil, nil,
        nil, 2, nil, 1, nil, nil, nil,
        nil, 2, nil, 1, nil, nil, nil,
      ]
      assert {:ok, :win, 1, _board} = Connect.Game.Server.check_winner(game)
    end

    test "simple left-down right-up diagonal win from left", %{diag_simple: game} do
      {:ok, _new_state} = GenServer.call(game, {:priv_set_board, [
        nil, 1,   nil,
        1,   nil, 2,
        2,   nil, nil
      ]})
      assert {:ok, :win, 1, _board} = Connect.Game.Server.check_winner(game)
    end

    test "simple left-down right-up diagonal win from bottom", %{diag_simple: game} do
      {:ok, _new_state} = GenServer.call(game, {:priv_set_board, [
        nil, nil, nil,
        nil, nil, 2,
        nil, 2,   nil
      ]})
      assert {:ok, :win, 2, _board} = Connect.Game.Server.check_winner(game)
    end

    test "simple right-down left-up diagonal win from right", %{diag_simple: game} do
      {:ok, _new_state} = GenServer.call(game, {:priv_set_board, [
        nil, 2,   nil,
        nil, nil, 2,
        nil, nil, nil
      ]})
      assert {:ok, :win, 2, _board} = Connect.Game.Server.check_winner(game)
    end

    test "simple right-down left-up diagonal win from bottom", %{diag_simple: game} do
      {:ok, _new_state} = GenServer.call(game, {:priv_set_board, [
        nil, nil, nil,
        1,   nil, nil,
        nil, 1,   nil
      ]})
      assert {:ok, :win, 1, _board} = Connect.Game.Server.check_winner(game)
    end

    test "complex left-down right-up diagonal win returns a new message type", %{connect_4: game} do
      Connect.Game.Server.make_move(game, 0)
      Connect.Game.Server.make_move(game, 1)
      Connect.Game.Server.make_move(game, 1)
      Connect.Game.Server.make_move(game, 2)
      Connect.Game.Server.make_move(game, 2)
      Connect.Game.Server.make_move(game, 3)
      Connect.Game.Server.make_move(game, 2)
      Connect.Game.Server.make_move(game, 3)
      Connect.Game.Server.make_move(game, 3)
      Connect.Game.Server.make_move(game, 5)
      assert {:ok, %{turn: 11, board: final_board, rows: 6, columns: 7, win_size: 4}} = Connect.Game.Server.make_move(game, 3)
      assert final_board == [
        nil, nil, nil, nil, nil, nil, nil,
        nil, nil, nil, nil, nil, nil, nil,
        nil, nil, nil, 1,   nil, nil, nil,
        nil, nil, 1,   1,   nil, nil, nil,
        nil, 1,   1,   2,   nil, nil, nil,
        1,   2,   2,   2,   nil, 2,   nil,
      ]
      assert {:ok, :win, 1, _board} = Connect.Game.Server.check_winner(game)
    end

    test "complex left-up right-down diagonal win returns a new message type", %{connect_4: game} do
      Connect.Game.Server.make_move(game, 6)
      Connect.Game.Server.make_move(game, 5)
      Connect.Game.Server.make_move(game, 5)
      Connect.Game.Server.make_move(game, 4)
      Connect.Game.Server.make_move(game, 4)
      Connect.Game.Server.make_move(game, 3)
      Connect.Game.Server.make_move(game, 4)
      Connect.Game.Server.make_move(game, 3)
      Connect.Game.Server.make_move(game, 3)
      Connect.Game.Server.make_move(game, 1)
      assert {:ok, %{turn: 11, board: final_board, rows: 6, columns: 7, win_size: 4}} = Connect.Game.Server.make_move(game, 3)
      assert final_board == [
        nil, nil, nil, nil, nil, nil, nil,
        nil, nil, nil, nil, nil, nil, nil,
        nil, nil, nil, 1,   nil, nil, nil,
        nil, nil, nil, 1,   1,   nil, nil,
        nil, nil, nil, 2,   1,   1,   nil,
        nil, 2,   nil, 2,   2,   2,   1,
      ]
      assert {:ok, :win, 1, _board} = Connect.Game.Server.check_winner(game)
    end
  end
end
