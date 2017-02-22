defmodule Game.RoundSupervisor do
  use Supervisor

  def start_child(category) do
    Supervisor.start_child(__MODULE__, [category])
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
