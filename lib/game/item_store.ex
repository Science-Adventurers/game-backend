defmodule Game.ItemStore do
  @data_file :code.priv_dir(:game)
             |> List.to_string
             |> Path.join("data/smg_ondisplay_with_image.json")
             |> IO.inspect

  def create_table do
    :ets.new(__MODULE__, [:public,
                          :named_table,
                          read_concurrency: true])
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
    @data_file
    |> File.stream!
    |> Stream.map(fn(line) ->
      spawn_link(fn() -> process_line(line) end)
    end)
    |> Stream.run
  end

  defp process_line(line) do
    decoded = Poison.decode!(line)
    data = Map.get(decoded, "_source")
    item = Game.Item.from_raw_source(data)
    :ets.insert(__MODULE__, {item.id, item.category, item})
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
