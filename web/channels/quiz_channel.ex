defmodule Game.QuizChannel do
  use Game.Web, :channel

  def join("quiz", _params, socket) do
    {:ok, socket}
  end

  def handle_in("get-random-question", %{"category" => category}, socket) do
    data = category
           |> Game.Command.get_random_question
           |> Map.from_struct
           |> Map.delete(:item)

    {:reply, {:ok, %{question: data}}, socket}
  end
end
