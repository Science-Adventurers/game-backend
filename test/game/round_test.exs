defmodule Game.RoundTest do
  use ExUnit.Case

  setup do
    {:ok, round} = Game.Round.start_link("Mathematics")

    {:ok, round: round}
  end

  test "stores the category", %{round: round}  do
    assert "Mathematics" == Game.Round.get_data(round).category
  end

  test "join/2 doesn't create duplicates", %{round: round} do
    :ok = Game.Round.join(round, "Triangles")
    :ok = Game.Round.join(round, "Triangles")

    assert MapSet.new(["Triangles"]) == Game.Round.get_data(round).players
  end

  test "switches to running state when 3 players join", %{round: round} do
    :ok = Game.Round.join(round, "Triangles")
    :ok = Game.Round.join(round, "Squares")
    :ok = Game.Round.join(round, "Circles")

    assert {:running, _} = :sys.get_state(round)
  end
end
