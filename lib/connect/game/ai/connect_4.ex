defmodule Connect.Game.Ai.Connect4 do
  def get_placement(game_state, ai_player) do
    empty_scores = List.duplicate(nil, game_state[:columns])
    populated_scores = compute_move_scores(game_state, ai_player, 1, empty_scores)

    index = case ai_player do
      1 ->
        max_score = Enum.max_by(populated_scores, fn(score) -> score || -100000 end)
        Enum.find_index(populated_scores, &(&1 == max_score))
      2 ->
        min_score = Enum.min_by(populated_scores, fn(score) -> score || 100000 end)
        Enum.find_index(populated_scores, &(&1 == min_score))
    end
    {:ok, index}
  end

  def compute_move_scores(state, player, _depth, scores) do
    columns = 0..state[:columns]-1
    column_scores = Enum.reduce(columns, scores, fn(column_to_place, scores) ->
      case Connect.Game.ColumnPlacement.find_placement(state, column_to_place) do
        {:ok, place_index} ->
          has_win = Connect.Game.WinCheck.check_winner(state[:board], state[:columns], state[:win_size])
          score_modifier = if player == 1, do: 1000, else: -1000
          score_modifier = if has_win, do: score_modifier, else: div(score_modifier, 1000)

          previous_score = Enum.at(scores, place_index) || 0
          next_scores = List.replace_at(scores, column_to_place, previous_score + score_modifier)
          next_scores
        {:error, _} -> scores
      end
    end)
    column_scores
  end
end
