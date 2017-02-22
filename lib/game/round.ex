defmodule Game.Round do
  @behaviour :gen_statem
  @number_of_questions 5

  alias Game.{ItemStore, Question, RoundRegistry}

  defmodule PlayerState do
    defstruct current_question: nil,
              remaining_questions: [],
              answers: %{}
  end

  defmodule Data do
    defstruct category: nil,
              max_players: 3,
              players: %{},
              current_question: nil,
              remaining_questions: []
  end

  ### Public api ###

  def start_link(category, max_players) do
    :gen_statem.start_link(via_tuple(category), __MODULE__, {category, max_players}, [])
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

  def answer(category, player_name, answer, elapsed_time) when is_binary(category) do
    :gen_statem.call(via_tuple(category), {:answer, player_name, answer, elapsed_time})
  end
  def answer(round, player_name, answer, elapsed_time) do
    :gen_statem.call(round, {:answer, player_name, answer, elapsed_time})
  end

  def via_tuple(category) do
    {:via, Registry, {RoundRegistry, category}}
  end

  def calculate_score(answers_map) do
    Enum.reduce(answers_map, 0, fn({question, {answer, elapsed_time}}, acc) ->
      if question.answer == answer do
        acc + penalized_score(elapsed_time)
      else
        acc
      end
    end)
  end

  ### Mandatory callbacks ###

  def init({category, max_players}) do
    options_pool = ItemStore.options_pool(category)
    questions = category
                |> ItemStore.random_from_category(@number_of_questions)
                |> Enum.map(fn(item) -> Question.from_item(item, options_pool) end)
    [current | remaining] = questions
    data = %Data{category: category,
                 max_players: max_players,
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
  def waiting_for_players({:call, from}, {:answer, _, _, _}, data) do
    reply = {:error, :not_running}
    {:next_state, :waiting_for_players, data, [{:reply, from, reply}]}
  end
  def waiting_for_players(event_type, event_content, data) do
    handle_event(event_type, event_content, data)
  end

  def running({:call, from}, {:join, _player_name}, data) do
    {:next_state, :running, data, [{:reply, from, {:error, :round_full}}]}
  end
  def running({:call, from}, {:answer, player_name, answer, elapsed_time}, data) do
    case Map.get(data.players, player_name) do
      nil ->
        {:next_state, :running, data, [{:reply, from, {:error, :not_joined}}]}
      %{current_question: nil} ->
        {:next_state, :running, data, [{:reply, from, {:error, :round_over}}]}
      %{current_question: current_question, remaining_questions: []} = player_state ->
        new_answers = Map.put(player_state.answers, current_question, {answer, elapsed_time})
        new_player_state = %{player_state | answers: new_answers,
                                            current_question: nil}
        new_players = Map.put(data.players, player_name, new_player_state)
        new_data = Map.put(data, :players, new_players)
        score = calculate_score(new_answers)
        if all_players_finished?(new_players) do
          record_score(new_data)
          {:next_state, :finish, new_data, [{:reply, from, {:ok, :round_over, score}},
                                            {:next_event, :internal, :stop}]}
        else
          {:next_state, :running, new_data, [{:reply, from, {:ok, :round_over, score}}]}
        end
      %{current_question: current_question, remaining_questions: [new_question | remaining]} = player_state ->
        new_player_state = %{player_state | answers: Map.put(player_state.answers, current_question, {answer, elapsed_time}),
                                            current_question: new_question,
                                            remaining_questions: remaining}
        new_players = Map.put(data.players, player_name, new_player_state)
        new_data = Map.put(data, :players, new_players)
        {:next_state, :running, new_data, [{:reply, from, {:ok, :next_round}}]}
    end
  end
  def running(event_type, event_content, data) do
    handle_event(event_type, event_content, data)
  end

  def finish(_, _, _) do
    {:stop, :normal}
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

  defp all_players_finished?(players) do
    players
    |> Map.values
    |> Enum.all?(fn(ps) ->
      ps.current_question == nil && ps.remaining_questions == []
    end)
  end

  defp record_score(data) do
    Enum.each(data.players, fn({name, state}) ->
      score = calculate_score(state.answers)
      Game.Leaderboard.record(name, data.category, score)
    end)
  end

  defp penalized_score(elapsed_time) when elapsed_time in (0..5000), do: 10
  defp penalized_score(elapsed_time) when elapsed_time in (5001..10000), do: 5
  defp penalized_score(elapsed_time) when elapsed_time > 10000, do: 2
end
