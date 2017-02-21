defmodule Game.QuizChannel do
  use Game.Web, :channel

  def join("quiz", _params, socket) do
    {:ok, socket}
  end
end
