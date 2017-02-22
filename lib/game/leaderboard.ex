defmodule Game.Leaderboard do
  def start_link do
    Agent.start_link(fn() -> [] end, name: __MODULE__)
  end

  def record(player_name, category, score) do
    Agent.cast(__MODULE__, fn(current) ->
      [%{player_name: player_name,
         category: category,
         score: score} | current]
    end)
  end

  def results do
    Agent.get(__MODULE__, fn(current) -> current end)
  end
end
