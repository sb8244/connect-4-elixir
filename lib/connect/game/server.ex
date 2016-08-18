defmodule Connect.Game.Server do
  use GenServer

  def start_link(name, args) do
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def get_state(server) do
    GenServer.call(server, {:state})
  end

  # Server Callbacks
  def init(%{rows: rows, columns: columns}) do
    blank_board = Tuple.duplicate(nil, rows * columns)
    {:ok, %{board: blank_board}}
  end

  def handle_call({:state}, _from, state) do
    {:reply, state, state}
  end
end
