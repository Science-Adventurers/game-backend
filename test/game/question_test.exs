defmodule Game.QuestionTest do
  use ExUnit.Case

  @item_json Path.expand("../fixtures/item.json", __DIR__)
             |> File.read!
             |> Poison.decode!

  @creators ["General Post Office", "David Edward Hughes",
             "Day and Son", "Nokia Corporation",
             "Sony Ericsson", "George W Bacon and Company",
             "Unknown maker", "CHARLES WHEATSTONE",
             "Huawei", "Siemens and Halske AG"]
  @locations ["United States", "Greenwich",
              "United Kingdom", "Stockholm",
              "England", "Camden",
              "Germany", "China",
              "Unknown place", "City of London"]
  @creation_dates ["1880-1958", "1857-1858",
                   "1900-1960", "1979-1985",
                   "1921", "1878-1890",
                   "1865-1867", "1992-1994",
                   "2005-2006", "1830-1900"]

  @options_pool %{creators: @creators,
                  locations: @locations,
                  creation_dates: @creation_dates}

  setup_all do
    item = @item_json
           |> Map.get("_source")
           |> Game.Item.from_raw_source
    {:ok, question: Game.Question.from_item(item, @options_pool)}
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

    test "has 4 options", %{question: question} do
      assert question.answer in question.options
      assert 4 == length(question.options)
    end
  end
end
