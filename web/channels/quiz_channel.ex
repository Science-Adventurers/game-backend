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
      payload = case data.current_question do
        nil ->
          %{type: "score",
            score: Round.calculate_score(data.answers)}
        current_question ->
          %{current_question: serialize_question(current_question),
            remaining_questions: Enum.map(data.remaining_questions, &serialize_question/1)}
      end
      {:reply, {:ok, payload}, assign(socket, :category, category)}
    else
      case Round.join(category, socket.assigns.player_name) do
        :ok ->
          {:ok, data} = Round.get_player_state(pid, socket.assigns.player_name)
          payload = case data.current_question do
            nil ->
              %{type: "score",
                score: Round.calculate_score(data.answers)}
            current_question ->
              %{current_question: serialize_question(current_question),
                remaining_questions: Enum.map(data.remaining_questions, &serialize_question/1)}
          end
          {:reply, {:ok, payload}, assign(socket, :category, category)}
        {:error, :round_full} ->
          {:reply, {:error, %{reason: "Round is full"}}, socket}
      end
    end
  end

  def handle_in("send-answer", %{"elapsed_time" => _elapsed_time, "answer" => answer}, socket) do
    %{player_name: player_name, category: category} = socket.assigns

    case Round.answer(category, player_name, answer) do
      {:ok, :next_round} ->
        {:ok, data} = Round.get_player_state(category, player_name)
        payload = %{type: "next-round",
                    current_question: serialize_question(data.current_question),
                    remaining_questions: Enum.map(data.remaining_questions, &serialize_question/1)}
        {:reply, {:ok, payload}, socket}
      {:ok, :round_over, score} ->
        payload = %{type: "score",
                    score: score}
        {:reply, {:ok, payload}, socket}
      error ->
        {:reply, {:error, %{reason: inspect(error)}}, socket}
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
