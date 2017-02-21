defmodule Game.QuestionsController do
  use Game.Web, :controller

  def random(conn, %{"category" => category}) do
    options_pool = %{
      creation_dates: Game.ItemStore.creation_dates_by_category(category),
      creators: Game.ItemStore.creators_by_category(category),
      locations: Game.ItemStore.locations_by_category(category),
    }

    item = Game.ItemStore.by_category(category) |> Enum.random

    question = Game.Question.from_item(item, options_pool)

    data = question
           |> Map.from_struct
           |> Map.delete(:item)

    json conn, data
  end
end
