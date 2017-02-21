defmodule Game.QuestionTest do
  use ExUnit.Case

  @item_json Path.expand("../fixtures/item.json", __DIR__)
             |> File.read!
             |> Poison.decode!

  setup_all do
    item = @item_json
           |> Map.get("_source")
           |> Game.Item.from_raw_source
    {:ok, question: Game.Question.from_item(item)}
  end

  describe "from_item/1" do
    test "has random topic", %{question: question} do
      assert question.topic in [:who, :where, :when]
    end

    test "has correct answer", %{question: question} do
      answers = ["1997-2001",
                 "Philips Electronics",
                 "France"]

      assert question.answer in answers
    end
  end
end
