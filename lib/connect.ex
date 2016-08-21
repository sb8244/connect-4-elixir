defmodule Connect do
  use Application

  def start(_type, _args) do
    Connect.Game.Server.start_link(:main, %{rows: 6, columns: 7, win_size: 4})
    Connect.Cli.Supervisor.start_link
  end
end
