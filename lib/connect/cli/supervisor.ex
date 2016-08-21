defmodule Connect.Cli.Supervisor do
  def start_link do
    import Supervisor.Spec

    children = [
      worker(Task, [Connect.Cli.Server, :start, []]),
    ]

    opts = [strategy: :one_for_one, name: Connect.Cli.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
