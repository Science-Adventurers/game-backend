defmodule Game.Question do
  defstruct item: nil,
            topic: nil,
            answer: nil,
            options: []

  @topics [:who, :where, :when]

  def from_item(item) do
    topic = random_topic!(item)
    answer = get_answer(item, topic)

    struct(__MODULE__, item: item,
                       topic: topic,
                       answer: answer)
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
end
