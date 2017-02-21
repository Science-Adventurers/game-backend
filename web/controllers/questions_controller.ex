defmodule Game.QuestionsController do
  use Game.Web, :controller

  def random(conn, %{"category" => category}) do
    data = category
           |> Game.Command.get_random_question
           |> Map.from_struct
           |> Map.delete(:item)

    json conn, data
  end
end
