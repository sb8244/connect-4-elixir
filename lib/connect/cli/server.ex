defmodule Connect.Cli.Server do
  def start do
    game_choice = IO.gets "Do you want to play Connect 4 (1) or Tic Tac Toe (2)\n"
    case game_choice do
      "1\n" ->
        {:ok, game} = Connect.Game.Server.start_link(nil, %{rows: 6, columns: 7, win_size: 4})
        IO.puts "Starting Connect 4!"
        play_game(game, 0)
      "2\n" ->
        {:ok, game} = Connect.Game.Server.start_link(nil, %{rows: 3, columns: 3, win_size: 3})
        IO.puts "Starting Tic Tac Toe!"
        play_game(game, 0)
      _ ->
        IO.puts "-_-"
        exit(:shutdown)
    end

    IO.gets "Game over! Enter to start a new game....."
  end

  defp play_game(game, turn) do
    current_player = rem(turn, 2) + 1
    IO.puts "Player #{current_player}'s turn. Which column (1-7) do you want to place?"
    print_board(game)
    placement = IO.gets ""
    IO.puts "\n\n"

    case Integer.parse(placement) do
      :error ->
        IO.puts IO.ANSI.format([:red, "Don't horse around. Please enter a number."])
        play_game(game, turn)
      {move, _} ->
        case Connect.Game.Server.make_move(game, move - 1) do
          {:ok, _board} ->
            case Connect.Game.Server.check_winner(game) do
              {:ok, :win, player, win_board} ->
                IO.puts "Winning board!"
                print_board(game)
                IO.puts "Wow! Player #{player} has won! Nice job."
              {:ok, _} ->
                play_game(game, turn + 1)
            end
          {:error, :column_full} ->
            IO.puts "This column is full. Please use a different column."
            play_game(game, turn)
        end
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
