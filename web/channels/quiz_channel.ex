defmodule Game.QuizChannel do
  use Game.Web, :channel

  alias Game.{Round, RoundSupervisor}

  def join("quiz", _params, socket) do
    {:ok, socket}
  end

  def handle_in("start-game", %{"category" => category}, socket) do
    {:ok, pid} = RoundSupervisor.get_or_start_round(category)

    questions = Round.get_data(pid).questions
                |> Enum.map(&serialize_question/1)

    {:reply, {:ok, %{questions: questions}}, assign(socket, :category, category)}
  end

  def handle_in("get-random-question", %{"category" => category}, socket) do
    data = category
           |> Game.Command.get_random_question
           |> serialize_question

    {:reply, {:ok, %{question: data}}, socket}
  end

  defp serialize_question(question) do
    question
    |> Map.from_struct
    |> Map.delete(:item)
  end
end
