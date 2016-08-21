defmodule Connect.Cli.Server do
  def start do
    game_choice = IO.gets "\nDo you want to play Connect 4 (1) or Tic Tac Toe (2)\n"
    case game_choice do
      "1\n" ->
        {:ok, game} = Connect.Game.Server.start_link(nil, %{rows: 6, columns: 7, win_size: 4})
        IO.puts "Starting Connect 4!\n\n"
        play_game(:connect_4, game, 0)
      "2\n" ->
        {:ok, game} = Connect.Game.Server.start_link(nil, %{rows: 3, columns: 3, win_size: 3})
        IO.puts "Starting Tic Tac Toe!\n\n"
        play_game(:tto, game, 0)
      _ ->
        IO.puts "-_-"
        exit(:shutdown)
    end

    IO.gets "Game over! Enter to start a new game....."
  end

  defp play_game(_type, _game, turn) when turn == nil do
  end

  defp play_game(:tto, game, turn) do
    current_player = rem(turn, 2) + 1
    IO.puts "Player #{current_player}'s turn."
    print_board(game)
    row = IO.gets "What row (1-3) do you want to place? "
    column = IO.gets "What column (1-3) do you want to place? "
    IO.puts "\n\n"

    next_turn = case {Integer.parse(row), Integer.parse(column)} do
      {:error, _} ->
        IO.puts IO.ANSI.format([:red, "Don't horse around. Please enter a number."])
        turn
      {_, :error} ->
        IO.puts IO.ANSI.format([:red, "Don't horse around. Please enter a number."])
        turn
      {{row_i, _}, {column_i, _}} ->
        IO.puts inspect(row_i)
        IO.puts inspect(column_i)
        move_result = Connect.Game.Server.make_move(game, row_i - 1, column_i - 1)
        get_next_turn_from_move(game, move_result, turn)
    end

    play_game(:tto, game, next_turn)
  end

  defp play_game(:connect_4, game, turn) do
    current_player = rem(turn, 2) + 1
    IO.puts "Player #{current_player}'s turn. Which column (1-7) do you want to place?"
    print_board(game)
    placement = IO.gets ""
    IO.puts "\n\n"

    next_turn = case Integer.parse(placement) do
      :error ->
        IO.puts IO.ANSI.format([:red, "Don't horse around. Please enter a number."])
        turn
      {move, _} ->
        move_result = Connect.Game.Server.make_move(game, move - 1)
        get_next_turn_from_move(game, move_result, turn)
    end

    play_game(:connect_4, game, next_turn)
  end

  defp get_next_turn_from_move(game, move_result, turn) do
    case move_result do
      {:ok, _board} ->
        case Connect.Game.Server.check_winner(game) do
          {:ok, :win, player, _win_board} ->
            IO.puts "Winning board!"
            print_board(game)
            IO.puts "Wow! Player #{player} has won! Nice job."
            nil
          {:ok, _} ->
            turn + 1
        end
      {:error, :column_full} ->
        IO.puts IO.ANSI.format([:red, "This column is full. Please use a different column."])
        turn
      {:error, :invalid_move} ->
        IO.puts IO.ANSI.format([:red, "This move is not valid. Please make a different move."])
        turn
    end
  end

  defp print_board(game) do
    game_state = Connect.Game.Server.get_state(game)
    rows = Enum.chunk(game_state[:board], game_state[:columns])
    Enum.each(rows, fn(row) ->
      IO.puts Enum.map(row, fn(place) ->
        case place do
          1 -> IO.ANSI.format([:red, "X"])
          2 -> IO.ANSI.format([:blue, "O"])
          nil -> '_'
        end
      end)
    end)
  end
end
