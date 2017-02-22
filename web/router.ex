defmodule Game.Router do
  use Game.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", Game do
    pipe_through :api

    resources "/leaderboard", LeaderboardController, only: [:index]
  end
end
