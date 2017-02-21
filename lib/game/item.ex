defmodule Game.Item do
  defstruct id: nil,
            category: nil,
            data: %{}

  def from_raw_source(source) do
    id = get_in(source, ["admin", "id"])
    [category] = get_in(source, ["categories", Access.all(), "name"])

    %__MODULE__{id: id,
                category: category,
                data: source}
  end
end
