defmodule Connect.Game.ServerTest do
  use ExUnit.Case, async: true

  setup context do
    {:ok, game} = Connect.Game.Server.start_link(context.test, %{rows: 2, columns: 3})
    {:ok, connect_4} = Connect.Game.Server.start_link(String.to_atom(to_string(context.test) <> "connect_4"), %{rows: 6, columns: 7})
    {:ok, game: game, connect_4: connect_4}
  end

  describe "call state" do
    test "an empty board is provided", %{game: game, connect_4: connect_4} do
      assert Connect.Game.Server.get_state(game) == %{board: {nil, nil, nil, nil, nil, nil}}
      assert Connect.Game.Server.get_state(connect_4) == %{board: Tuple.duplicate(nil, 42)}
    end
  end
end
