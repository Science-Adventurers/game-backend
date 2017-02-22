defmodule Game.LeaderboardController do
  use Game.Web, :controller

  def index(conn, _params) do
    json(conn, Game.Leaderboard.results)
  end
end
