defmodule Game.Question do
  defstruct name: nil,
            image_url: nil,
            item: nil,
            topic: nil,
            answer: nil,
            options: []

  @topics [:who, :where, :when]

  def from_item(item, options_pool) do
    topic = random_topic!(item)
    answer = get_answer(item, topic)
    options = get_options(options_pool, topic, answer)

    struct(__MODULE__, name: item.name,
                       image_url: item.image_url,
                       item: item,
                       topic: topic,
                       answer: answer,
                       options: options)
  end

  defp random_topic!(item) do
    item
    |> available_topics()
    |> Enum.random()
  end

  defp available_topics(item) do
    Enum.filter(@topics, fn(t) ->
      is_topic_available?(item, t)
    end)
  end

  defp is_topic_available?(item, :who) do
    item.creator !== :not_available
  end
  defp is_topic_available?(item, :when) do
    item.creation_date !== :not_available
  end
  defp is_topic_available?(item, :where) do
    item.location !== :not_available
  end

  defp get_answer(item, :who) do
    {:available, value} = item.creator
    value
  end
  defp get_answer(item, :when) do
    {:available, value} = item.creation_date
    value
  end
  defp get_answer(item, :where) do
    {:available, value} = item.location
    value
  end

  defp get_options(options_pool, topic, answer) do
    options = Map.get(options_pool, topic_to_option(topic))
              |> Enum.take_random(4)
    if Enum.member?(options, answer) do
      options
    else
      [answer | Enum.take_random(options, 3)]
      |> Enum.shuffle
    end
  end

  defp topic_to_option(:who), do: :creators
  defp topic_to_option(:when), do: :creation_dates
  defp topic_to_option(:where), do: :locations
end
