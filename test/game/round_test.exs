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

    assert data.current_question.item.category == "Mathematics"
    assert Enum.all?(data.remaining_questions, fn(q) -> q.item.category == "Mathematics" end)
  end
end
