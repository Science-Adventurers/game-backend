defmodule Game.Router do
  use Game.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/questions", Game do
    pipe_through :api

    get "/random", QuestionsController, :random
  end
end
