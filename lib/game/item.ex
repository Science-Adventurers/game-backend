defmodule Game.Item do
  defstruct id: nil,
            name: nil,
            image_url: nil,
            category: nil,
            creator: :not_available,
            creation_date: :not_available,
            location: :not_available,
            data: %{}

  @image_base_url "http://smgco-images.s3.amazonaws.com/media/"

  def from_raw_source(source) do
    id = get_in(source, ["admin", "id"])
    name = get_in(source, ["title", Access.at(0), "value"])
    image_path = get_in(source, ["multimedia", Access.at(0),
                                 "processed", "large_thumbnail",
                                 "location"])
    [category] = get_in(source, ["categories", Access.all(), "name"])
    creation = get_creation(source)

    creator = get_creator(creation)
    creation_date = get_creation_date(creation)
    location = get_location(creation)

    %__MODULE__{id: id,
                name: name,
                image_url: @image_base_url <> image_path,
                category: category,
                creator: creator,
                creation_date: creation_date,
                location: location,
                data: source}
  end

  def can_generate_question?(item) do
    item.creator !== :not_available
      or item.creation_date !== :not_available
      or item.location !== :not_available
  end

  defp get_creation(source) do
    get_in(source, ["lifecycle", "creation"])
  end

  defp get_creation_date(nil), do: :not_available
  defp get_creation_date([]), do: :not_available
  defp get_creation_date([value | _]) do
    get_date(value)
  end

  defp get_creator(nil), do: :not_available
  defp get_creator([]), do: :not_available
  defp get_creator([value | _]) do
    get_maker(value)
  end

  defp get_location(nil), do: :not_available
  defp get_location([]), do: :not_available
  defp get_location([value | _]) do
    get_place(value)
  end

  defp get_date(%{"date" => date}) do
    case get_in(date, [Access.at(0), "value"]) do
      nil -> :not_available
      value -> {:available, value}
    end
  end
  defp get_date(_), do: :not_available

  defp get_maker(%{"maker" => maker}) do
    case get_in(maker, [Access.at(0), "summary_title"]) do
      nil -> :not_available
      value -> {:available, value}
    end
  end
  defp get_maker(_), do: :not_available

  defp get_place(%{"places" => place}) do
    case get_in(place, [Access.at(0), "summary_title"]) do
      nil -> :not_available
      value -> {:available, value}
    end
  end
  defp get_place(_), do: :not_available
end
