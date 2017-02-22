defmodule Game.Round do
  @behaviour :gen_statem
  @number_of_questions 10

  alias Game.{ItemStore, Question, RoundRegistry}

  defmodule PlayerState do
    defstruct current_question: nil,
              remaining_questions: []
  end

  defmodule Data do
    defstruct category: nil,
              max_players: 3,
              players: %{},
              current_question: nil,
              remaining_questions: []
  end

  ### Public api ###

  def start_link(category) do
    :gen_statem.start_link(via_tuple(category), __MODULE__, category, [])
  end

  def join(category, player_name) when is_binary(category) do
    :gen_statem.call(via_tuple(category), {:join, player_name})
  end
  def join(round, player_name) do
    :gen_statem.call(round, {:join, player_name})
  end

  def has_player?(category, player_name) when is_binary(category) do
    :gen_statem.call(via_tuple(category), {:has_player?, player_name})
  end
  def has_player?(round, player_name) do
    :gen_statem.call(round, {:has_player?, player_name})
  end

  def get_player_state(category, player_name) when is_binary(category) do
    :gen_statem.call(via_tuple(category), {:get_player_state, player_name})
  end
  def get_player_state(round, player_name) do
    :gen_statem.call(round, {:get_player_state, player_name})
  end

  def get_data(category) when is_binary(category) do
    :gen_statem.call(via_tuple(category), :get_data)
  end
  def get_data(round) do
    :gen_statem.call(round, :get_data)
  end

  def via_tuple(category) do
    {:via, Registry, {RoundRegistry, category}}
  end

  ### Mandatory callbacks ###

  def init(category) do
    options_pool = ItemStore.options_pool(category)
    questions = category
                |> ItemStore.random_from_category(@number_of_questions)
                |> Enum.map(fn(item) -> Question.from_item(item, options_pool) end)
    [current | remaining] = questions
    data = %Data{category: category,
                 current_question: current,
                 remaining_questions: remaining}
    {:ok, :waiting_for_players, data}
  end

  def terminate(_reason, _state, _data) do
    :ok
  end

  def callback_mode, do: :state_functions

  def code_change(_vsn, state, data, _extra) do
    {:ok, state, data}
  end

  ### State transitions ###

  def waiting_for_players({:call, from}, {:join, player_name}, data) do
    new_players = Map.put_new(data.players,
                              player_name,
                              %PlayerState{current_question: data.current_question,
                                           remaining_questions: data.remaining_questions})
    new_data = %{data | players: new_players}
    new_state = if Map.size(new_players) >= data.max_players do
      :running
    else
      :waiting_for_players
    end
    {:next_state, new_state, new_data, [{:reply, from, :ok}]}
  end
  def waiting_for_players(event_type, event_content, data) do
    handle_event(event_type, event_content, data)
  end

  def running({:call, from}, {:join, _player_name}, data) do
    {:next_state, :running, data, [{:reply, from, {:error, :round_full}}]}
  end
  def running(event_type, event_content, data) do
    handle_event(event_type, event_content, data)
  end

  ### Common events ###

  defp handle_event({:call, from}, :get_data, data) do
    {:keep_state, data, [{:reply, from, data}]}
  end
  defp handle_event({:call, from}, {:has_player?, player_name}, data) do
    has_player = Map.has_key?(data.players, player_name)
    {:keep_state, data, [{:reply, from, has_player}]}
  end
  defp handle_event({:call, from}, {:get_player_state, player_name}, data) do
    reply = case Map.get(data.players, player_name) do
      nil ->
        {:error, :not_joined}
      state ->
        {:ok, state}
    end
    {:keep_state, data, [{:reply, from, reply}]}
  end
end
