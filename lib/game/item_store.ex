defmodule Game.ItemStore do
  @data_file :code.priv_dir(:game)
             |> List.to_string
             |> Path.join("data/smg_ondisplay_with_image.json")

  def create_table do
    :ets.new(__MODULE__, [:public,
                          :named_table,
                          read_concurrency: true])
  end

  def all do
    :ets.select(__MODULE__, [{{:"_", :"_", :"$1"}, [], [:"$1"]}])
  end

  def by_category(name) do
    :ets.select(__MODULE__, [{{:"_", name, :"$1"}, [], [:"$1"]}])
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
end
