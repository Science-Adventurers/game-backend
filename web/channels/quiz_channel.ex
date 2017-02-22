defmodule Game.QuizChannel do
  use Game.Web, :channel

  alias Game.{Round, RoundSupervisor}

  def join("quiz", %{"player_name" => name}, socket) do
    {:ok, assign(socket, :player_name, name)}
  end

  def handle_in("start-game", %{"category" => category}, socket) do
    {:ok, pid} = RoundSupervisor.get_or_start_round(category)
    if Round.has_player?(pid, socket.assigns.player_name) do
      {:ok, data} = Round.get_player_state(pid, socket.assigns.player_name)
      payload = %{current_question: serialize_question(data.current_question),
                  remaining_questions: Enum.map(data.remaining_questions, &serialize_question/1)}
      {:reply, {:ok, payload}, assign(socket, :category, category)}
    else
      case Round.join(category, socket.assigns.player_name) do
        :ok ->
          {:ok, data} = Round.get_player_state(pid, socket.assigns.player_name)
          payload = %{current_question: serialize_question(data.current_question),
                      remaining_questions: Enum.map(data.remaining_questions, &serialize_question/1)}
          {:reply, {:ok, payload}, assign(socket, :category, category)}
        {:error, :round_full} ->
          {:reply, {:error, %{reason: "Round is full"}}, socket}
      end
    end
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
  end
end
