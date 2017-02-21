defmodule Game.ItemStore do
  use GenServer

  @data_file :code.priv_dir(:game)
             |> List.to_string
             |> Path.join("data/smg_ondisplay_with_image.json")

  def create_table do
    :ets.new(__MODULE__, [:public,
                          :named_table,
                          read_concurrency: true])
  end

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    send(self(), :parse_items)
    {:ok, []}
  end

  def handle_info(:parse_items, state) do
    @data_file
    |> File.stream!
    |> Stream.map(fn(line) ->
      spawn_link(fn() -> process_line(line) end)
    end)
    |> Stream.run
    {:noreply, state}
  end

  defp process_line(line) do
    decoded = Poison.decode!(line)

    data = Map.get(decoded, "_source")
    id = Map.get(decoded, "_id")

    :ets.insert(__MODULE__, {id, data})
  end
end
