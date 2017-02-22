defmodule Game.ItemStore do
  def create_table do
    :ets.new(__MODULE__, [:public,
                          :named_table,
                          read_concurrency: true])
  end

  def options_pool(name) do
    %{creators: creators_by_category(name),
      locations: locations_by_category(name),
      creation_dates: creation_dates_by_category(name)}
  end

  def random_from_category(name, count) do
    name
    |> by_category
    |> Enum.take_random(count)
  end

  def locations_by_category(name) do
    name
    |> match_spec_for_location
    |> get_all
    |> Enum.uniq
  end

  def creators_by_category(name) do
    name
    |> match_spec_for_creator
    |> get_all
    |> Enum.uniq
  end

  def creation_dates_by_category(name) do
    name
    |> match_spec_for_creation_date
    |> get_all
    |> Enum.uniq
  end

  def all do
    get_all({:"_", :"_", :"$1"})
  end

  def by_category(name) do
    get_all({:"_", name, :"$1"})
  end

  def populate! do
    data_file()
    |> File.stream!
    |> Stream.map(fn(line) ->
      spawn_link(fn() -> process_line(line) end)
    end)
    |> Stream.run
  end

  defp data_file do
    Application.get_env(:game, :data_path)
  end

  defp process_line(line) do
    decoded = Poison.decode!(line)
    data = Map.get(decoded, "_source")
    item = Game.Item.from_raw_source(data)
    if Game.Item.can_generate_question?(item) do
      :ets.insert(__MODULE__, {item.id, item.category, item})
    else
      :noop
    end
  end

  defp get_all(match_head) do
    :ets.select(__MODULE__, [{match_head, [], [:"$1"]}])
  end

  defp match_spec_for_location(category_name) do
    {:"_", category_name, %{location: {:available, :"$1"}}}
  end
  defp match_spec_for_creator(category_name) do
    {:"_", category_name, %{creator: {:available, :"$1"}}}
  end
  defp match_spec_for_creation_date(category_name) do
    {:"_", category_name, %{creation_date: {:available, :"$1"}}}
  end
end
