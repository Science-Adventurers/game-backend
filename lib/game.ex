defmodule Game do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(Registry, [:unique, Game.RoundRegistry]),
      supervisor(Game.Endpoint, []),
      supervisor(Game.RoundSupervisor, []),
      worker(Game.Leaderboard, [])
      # Start your own worker by calling: Game.Worker.start_link(arg1, arg2, arg3)
      # worker(Game.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Game.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Game.Endpoint.config_change(changed, removed)
    :ok
  end

  def start_phase(:create_item_store_table, _, _) do
    Game.ItemStore = Game.ItemStore.create_table()
    :ok
  end

  def start_phase(:populate_item_store, _, _) do
    :ok = Game.ItemStore.populate!
  end
end
