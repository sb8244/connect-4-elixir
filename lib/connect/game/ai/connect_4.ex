defmodule Connect.Game.Ai.Connect4 do
  def get_placement(game_state) do
    empty_scores = List.duplicate(nil, game_state[:columns])
    populated_scores = compute_move_scores(game_state, 2, 4, 4, empty_scores)

    max_score = Enum.max_by(populated_scores, fn(score) -> score || -100000 end)
    index = Enum.find_index(populated_scores, &(&1 == max_score))
    {:ok, index}
  end

  def compute_move_scores(_state, _player, _start_depth, depth, scores) when depth == 0 do
    scores
  end

  def compute_move_scores(state, player, start_depth, depth, scores) do
    columns = 0..state[:columns]-1
    Enum.reduce(columns, scores, fn(column_to_place, scores) ->
      case Connect.Game.ColumnPlacement.find_placement(state, column_to_place) do
        {:ok, place_index} ->
          next_board = List.replace_at(state[:board], place_index, player)
          has_win = Connect.Game.WinCheck.check_winner(next_board, state[:columns], state[:win_size])
          score_modifier = cond do
            has_win && start_depth == depth -> 100000
            has_win -> 1000
            true -> 0
          end
          score_modifier = score_modifier * cond do
            player == 1 && has_win -> -100
            player == 1 -> -10
            player == 2 -> 1
          end

          next_state = Map.merge(state, %{board: next_board})

          previous_score = Enum.at(scores, place_index) || 0
          computed_scores = cond do
            has_win -> []
            true -> compute_move_scores(next_state, rem(player,2)+1, start_depth, depth-1, List.duplicate(nil, Enum.count(scores)))
          end

          computed_sum = Enum.sum(Enum.map(computed_scores, &(&1 || 0)))
          List.replace_at(scores, column_to_place, previous_score + score_modifier + computed_sum)
        {:error, _} -> scores
      end
    end)
  end
end
