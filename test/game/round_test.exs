defmodule Game.RoundTest do
  use ExUnit.Case

  setup do
    max_players = 3
    {:ok, round} = Game.Round.start_link("Mathematics", max_players)

    {:ok, round: round}
  end

  test "stores the category", %{round: round}  do
    assert "Mathematics" == Game.Round.get_data(round).category
  end

  test "join/2 doesn't create duplicates", %{round: round} do
    :ok = Game.Round.join(round, "Triangles")
    :ok = Game.Round.join(round, "Triangles")

    assert Map.has_key?(Game.Round.get_data(round).players, "Triangles")
  end

  test "join/2 sets the player state", %{round: round} do
    :ok = Game.Round.join(round, "Triangles")

    data = Game.Round.get_data(round)
    player_state = Map.get(data.players, "Triangles")

    assert data.current_question == player_state.current_question
    assert data.remaining_questions == player_state.remaining_questions
  end

  test "cannot join a full game", %{round: round} do
    :ok = Game.Round.join(round, "Triangles")
    :ok = Game.Round.join(round, "Squares")
    :ok = Game.Round.join(round, "Circles")

    assert {:error, :round_full} == Game.Round.join(round, "Cubes")
  end

  test "has_player?/2", %{round: round} do
    :ok = Game.Round.join(round, "Triangles")

    assert Game.Round.has_player?(round, "Triangles")
    refute Game.Round.has_player?(round, "Squares")
  end

  test "player_state/2", %{round: round} do
    :ok = Game.Round.join(round, "Triangles")

    assert {:ok, _} = Game.Round.get_player_state(round, "Triangles")
    assert {:error, :not_joined} = Game.Round.get_player_state(round, "Squares")
  end

  test "switches to running state when 3 players join", %{round: round} do
    :ok = Game.Round.join(round, "Triangles")
    :ok = Game.Round.join(round, "Squares")
    :ok = Game.Round.join(round, "Circles")

    assert {:running, _} = :sys.get_state(round)
  end

  test "it generates 10 random questions for that category", %{round: round} do
    data = Game.Round.get_data(round)

    assert data.current_question.category == "Mathematics"
    assert Enum.all?(data.remaining_questions, fn(q) -> q.category == "Mathematics" end)
  end

  test "cannot answer a non-running game", %{round: round} do
    :ok = Game.Round.join(round, "Triangles")
    assert {:error, :not_running} == Game.Round.answer(round, "Triangles", "not-important")
  end

  test "can answer a running game", %{round: round} do
    :ok = Game.Round.join(round, "Triangles")
    :ok = Game.Round.join(round, "Squares")
    :ok = Game.Round.join(round, "Circles")

    data = Game.Round.get_data(round)
    old_player_state = Map.get(data.players, "Triangles")

    {:ok, :next_round} = Game.Round.answer(round, "Triangles", "1902")

    data = Game.Round.get_data(round)
    new_player_state = Map.get(data.players, "Triangles")

    assert 4 == length(old_player_state.remaining_questions)
    assert 3 == length(new_player_state.remaining_questions)
    assert old_player_state.current_question !== new_player_state.current_question
    assert old_player_state.answers == %{}
    assert new_player_state.answers == %{old_player_state.current_question => "1902"}
  end

  test "finishing a game", %{round: round} do
    :ok = Game.Round.join(round, "Triangles")
    :ok = Game.Round.join(round, "Squares")
    :ok = Game.Round.join(round, "Circles")

    Enum.each(1..4, fn(_) ->
      {:ok, :next_round} = Game.Round.answer(round, "Triangles", "1902")
    end)

    {:ok, :round_over, score} = Game.Round.answer(round, "Triangles", "1902")

    assert score >= 0
    assert {:error, :round_over} == Game.Round.answer(round, "Triangles", "1902")
  end

  test "all players finish", %{round: round} do
    :ok = Game.Round.join(round, "Triangles")
    :ok = Game.Round.join(round, "Squares")
    :ok = Game.Round.join(round, "Circles")

    Enum.each(1..4, fn(_) ->
      {:ok, :next_round} = Game.Round.answer(round, "Triangles", "1902")
    end)
    Enum.each(1..4, fn(_) ->
      {:ok, :next_round} = Game.Round.answer(round, "Squares", "1902")
    end)
    Enum.each(1..4, fn(_) ->
      {:ok, :next_round} = Game.Round.answer(round, "Circles", "1902")
    end)

    {:ok, :round_over, _score} = Game.Round.answer(round, "Triangles", "1902")
    {:ok, :round_over, _score} = Game.Round.answer(round, "Squares", "1902")
    {:ok, :round_over, _score} = Game.Round.answer(round, "Circles", "1902")

    assert Process.info(round) == nil
  end
end
