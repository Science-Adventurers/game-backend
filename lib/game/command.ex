defmodule Game.Command do
  def get_random_question(category) do
    options_pool = %{
      creation_dates: Game.ItemStore.creation_dates_by_category(category),
      creators: Game.ItemStore.creators_by_category(category),
      locations: Game.ItemStore.locations_by_category(category),
    }

    item = Game.ItemStore.by_category(category) |> Enum.random

    Game.Question.from_item(item, options_pool)
  end
end
