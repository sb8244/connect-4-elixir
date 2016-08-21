defmodule Connect.Game.Ai.Connect4Test do
  use ExUnit.Case, async: true

  describe "get_placement" do
    test "picks an opening move", context do
      {:ok, game} = Connect.Game.Server.start_link(context.test, %{rows: 3, columns: 3, win_size: 3})
      {:ok, state} = GenServer.call(game, {:priv_set_board, [
        nil, nil, nil,
        nil, nil, nil,
        1, nil, nil
      ]})
      assert Connect.Game.Ai.Connect4.get_placement(state, 1) == {:ok, 0}
    end

    test "it gives the only move on a nearly full board", context do
      {:ok, game} = Connect.Game.Server.start_link(context.test, %{rows: 2, columns: 2, win_size: 3})
      {:ok, state} = GenServer.call(game, {:priv_set_board, [
        2, nil,
        1, 1
      ]})
      assert Connect.Game.Ai.Connect4.get_placement(state, 2) == {:ok, 1}
    end

    test "it gives the only move on a nearly full board for player 1", context do
      {:ok, game} = Connect.Game.Server.start_link(context.test, %{rows: 2, columns: 2, win_size: 3})
      {:ok, state} = GenServer.call(game, {:priv_set_board, [
        2, nil,
        1, 2
      ]})
      assert Connect.Game.Ai.Connect4.get_placement(state, 1) == {:ok, 1}
    end

    test "prefers a 1-move win over a not winning move", context do
      {:ok, game} = Connect.Game.Server.start_link(context.test, %{rows: 3, columns: 3, win_size: 3})
      {:ok, state} = GenServer.call(game, {:priv_set_board, [
        1, 2,   nil,
        2, nil, 1,
        1, 2,   2
      ]})
      assert Connect.Game.Ai.Connect4.get_placement(state, 1) == {:ok, 1}
    end
  end

  describe "compute_move_scores" do
    test "produces the correct placement scores on a simple board", context do
      {:ok, game} = Connect.Game.Server.start_link(context.test, %{rows: 2, columns: 2, win_size: 3})
      {:ok, state} = GenServer.call(game, {:priv_set_board, [
        2, nil,
        1, 1
      ]})
      empty_scores = List.duplicate(nil, state[:columns])
      assert Connect.Game.Ai.Connect4.compute_move_scores(state, 2, 1, empty_scores) == [nil, -1]
    end

    test "inverts the score to be positive for player 1", context do
      {:ok, game} = Connect.Game.Server.start_link(context.test, %{rows: 2, columns: 2, win_size: 3})
      {:ok, state} = GenServer.call(game, {:priv_set_board, [
        2, nil,
        1, 1
      ]})
      empty_scores = List.duplicate(nil, state[:columns])
      assert Connect.Game.Ai.Connect4.compute_move_scores(state, 1, 1, empty_scores) == [nil, 1]
    end

    test "gives a large score to winning moves for player 1", context do
      {:ok, game} = Connect.Game.Server.start_link(context.test, %{rows: 3, columns: 3, win_size: 3})
      {:ok, state} = GenServer.call(game, {:priv_set_board, [
        1, 2, nil,
        2, 1, 1,
        1, 2, 2
      ]})
      empty_scores = List.duplicate(nil, state[:columns])
      assert Connect.Game.Ai.Connect4.compute_move_scores(state, 1, 1, empty_scores) == [nil, nil, 1000]
    end

    test "gives a low score to winning moves for player 2", context do
      {:ok, game} = Connect.Game.Server.start_link(context.test, %{rows: 3, columns: 3, win_size: 3})
      {:ok, state} = GenServer.call(game, {:priv_set_board, [
        1, 2,   1,
        2, nil, 1,
        1, 2,   2
      ]})
      empty_scores = List.duplicate(nil, state[:columns])
      assert Connect.Game.Ai.Connect4.compute_move_scores(state, 2, 1, empty_scores) == [nil, -1000, nil]
    end
  end
end
