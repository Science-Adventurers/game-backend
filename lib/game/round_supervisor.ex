defmodule Game.RoundSupervisor do
  use Supervisor

  def get_or_start_round(category) do
    case Registry.lookup(Game.RoundRegistry, category) do
      [] -> start_child(category)
      [{pid, _}] -> {:ok, pid}
    end
  end

  def start_child(category) do
    Supervisor.start_child(__MODULE__, [category, 1])
  end

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(Game.Round, [])
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
