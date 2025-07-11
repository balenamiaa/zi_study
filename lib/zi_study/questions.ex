defmodule ZiStudy.Questions do
  @moduledoc """
  The Questions context.
  Provides functions for managing Questions, QuestionSets, and Tags.
  """

  import Ecto.Query, warn: false
  require Logger
  alias ZiStudy.Repo

  alias ZiStudy.Accounts.User
  alias ZiStudy.Questions.Question
  alias ZiStudy.Questions.QuestionSet
  alias ZiStudy.Questions.Tag
  alias ZiStudy.Questions.Answer

  alias ZiStudy.QuestionsOps.Converter
  alias ZiStudy.QuestionsOps.JsonSerializer
  alias ZiStudy.QuestionsOps.Processed

  @doc """
  Returns a list of all question sets.

  When `user_id` is provided:
  - If `show_only_owned` is true, only shows sets owned by the user (both private and public)
  - If `show_only_owned` is false, shows all sets owned by user + public sets owned by others

  When `user_id` is nil, only public sets are returned (show_only_owned is ignored).
  """
  def list_question_sets(user_id \\ nil, show_only_owned \\ false) do
    QuestionSet
    |> (fn query ->
          if user_id do
            if show_only_owned do
              from qs in query,
                where: qs.owner_id == ^user_id
            else
              from qs in query,
                where: qs.owner_id == ^user_id or not qs.is_private
            end
          else
            from qs in query,
              where: not qs.is_private
          end
        end).()
    |> Repo.all()
  end

  @doc """
  Gets a single question set by its ID.

  Preloads associated tags and questions.
  """
  def get_question_set(id) do
    QuestionSet
    |> Repo.get(id)
    |> case do
      nil -> nil
      question_set -> Repo.preload(question_set, [:tags, questions: [:answers]])
    end
  end

  @doc """
  Creates a question set.
  """
  def create_question_set(%User{} = user, attrs \\ %{}) do
    # Normalize string keys to atom keys for the changeset
    normalized_attrs =
      for {key, value} <- attrs, into: %{} do
        case key do
          key when is_binary(key) -> {String.to_atom(key), value}
          key when is_atom(key) -> {key, value}
        end
      end

    attrs_with_owner = Map.put(normalized_attrs, :owner_id, user.id)

    %QuestionSet{}
    |> QuestionSet.changeset(attrs_with_owner)
    |> Repo.insert()
  end

  @doc """
  Creates a question set without an owner.
  These sets are always public by default.
  """
  def create_question_set_ownerless(attrs \\ %{}) do
    # Extract tags if provided
    {tags, attrs_without_tags} = Map.pop(attrs, :tags, [])

    # Normalize string keys to atom keys for the changeset
    normalized_attrs =
      for {key, value} <- attrs_without_tags, into: %{} do
        case key do
          key when is_binary(key) -> {String.to_atom(key), value}
          key when is_atom(key) -> {key, value}
        end
      end

    attrs_normalized =
      normalized_attrs
      |> Map.put_new(:owner_id, nil)
      |> Map.put_new(:is_private, false)

    case Repo.transaction(fn ->
           # Create the question set
           changeset =
             %QuestionSet{}
             |> QuestionSet.changeset(attrs_normalized)

           case Repo.insert(changeset) do
             {:ok, question_set} ->
               # Add tags if provided
               if Enum.empty?(tags) do
                 question_set
               else
                 case add_tags_to_question_set(question_set, Enum.map(tags, & &1.name)) do
                   {:ok, updated_set} -> updated_set
                   {:error, reason} -> Repo.rollback(reason)
                 end
               end

             {:error, changeset} ->
               Repo.rollback(changeset)
           end
         end) do
      {:ok, question_set} -> {:ok, question_set}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Updates a question set.
  """
  def update_question_set(%QuestionSet{} = question_set, attrs) do
    # Preload tags if we're updating them
    question_set_with_tags =
      if Map.has_key?(attrs, :tags) || Map.has_key?(attrs, "tags") do
        Repo.preload(question_set, :tags)
      else
        question_set
      end

    question_set_with_tags
    |> QuestionSet.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a question set.
  """
  def delete_question_set(%QuestionSet{} = question_set) do
    Repo.delete(question_set)
  end

  defp add_questions_to_set_impl(
         %QuestionSet{} = question_set,
         question_data_for_assoc,
         _imported_questions_structs
       ) do
    max_position_query =
      from(qsj in "question_set_questions",
        where: qsj.question_set_id == ^question_set.id,
        select: max(qsj.position)
      )

    max_position = Repo.one(max_position_query) || 0

    # Get existing question IDs in this set to prevent duplicates
    existing_question_ids_query =
      from(qsj in "question_set_questions",
        where: qsj.question_set_id == ^question_set.id,
        select: qsj.question_id
      )

    existing_question_ids = MapSet.new(Repo.all(existing_question_ids_query))

    # Filter out questions that are already in the set
    new_questions =
      question_data_for_assoc
      |> Enum.reject(fn %{id: q_id} -> MapSet.member?(existing_question_ids, q_id) end)

    if Enum.empty?(new_questions) do
      # No new questions to add - all were duplicates
      {:ok, Repo.preload(question_set, :questions, force: true),
       %{skipped_duplicates: length(question_data_for_assoc)}}
    else
      Repo.transaction(fn ->
        Enum.with_index(new_questions, fn %{id: q_id, position: pos}, index ->
          actual_position = if pos, do: pos, else: max_position + index + 1

          Repo.insert_all("question_set_questions", [
            %{
              question_set_id: question_set.id,
              question_id: q_id,
              position: actual_position
            }
          ])
        end)

        updated_set = Repo.preload(question_set, :questions, force: true)
        skipped_count = length(question_data_for_assoc) - length(new_questions)

        if skipped_count > 0 do
          {:ok, updated_set, %{skipped_duplicates: skipped_count}}
        else
          {:ok, updated_set}
        end
      end)
    end
  end

  @doc """
  Removes questions from a question set.
  `question_ids` should be a list of question IDs.
  """
  def remove_questions_from_set(%QuestionSet{} = question_set, question_ids)
      when is_list(question_ids) do
    {count_deleted, _} =
      Repo.delete_all(
        from qsj in "question_set_questions",
          where: qsj.question_set_id == ^question_set.id and qsj.question_id in ^question_ids
      )

    {:ok, count_deleted}
  end

  @doc """
  Adds a list of questions to a question set.

  `questions` can be a list of:
  - Question structs
  - Question IDs (integers)
  - Maps with :id and optional :position keys

  If `user_id` is provided, authorization is checked to ensure the user can modify the question set.
  If positions are not specified, questions are appended to the end in the order provided.

  Returns `{:ok, updated_question_set}` on success or `{:error, reason}` on failure.
  """
  def add_questions_to_set(%QuestionSet{} = question_set, questions, user_id \\ nil)
      when is_list(questions) do
    # Authorization check if user_id is provided
    if user_id do
      # Reload the question set to get the latest data
      fresh_question_set = get_question_set(question_set.id)

      if fresh_question_set && fresh_question_set.owner_id == user_id do
        do_add_questions_to_set(fresh_question_set, questions)
      else
        {:error, :unauthorized}
      end
    else
      do_add_questions_to_set(question_set, questions)
    end
  end

  defp do_add_questions_to_set(question_set, questions) do
    question_data_for_assoc =
      questions
      |> Enum.map(fn question ->
        case question do
          %Question{id: id} ->
            %{id: id, position: nil}

          %{id: id, position: position} when is_integer(id) ->
            %{id: id, position: position}

          %{id: id} when is_integer(id) ->
            %{id: id, position: nil}

          id when is_integer(id) ->
            %{id: id, position: nil}

          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    if length(question_data_for_assoc) == 0 do
      {:error, :no_valid_questions}
    else
      case add_questions_to_set_impl(question_set, question_data_for_assoc, []) do
        {:ok, updated_set} -> {:ok, updated_set}
        {:ok, updated_set, info} -> {:ok, updated_set, info}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @doc """
  Returns a list of all questions.
  """
  def list_questions do
    Repo.all(Question)
  end

  @doc """
  Gets a single question by ID.
  """
  def get_question(id) do
    Question
    |> Repo.get(id)
    |> case do
      nil -> nil
      question -> Repo.preload(question, [:answers, :question_sets])
    end
  end

  @doc """
  Creates a question from processed content data.
  The `processed_question_content` should be one of the `ZiStudy.QuestionsOps.Processed.Question.*` structs.
  """
  def create_question(processed_question_content) do
    data_map = Processed.Question.to_map(processed_question_content)

    string_key_data =
      for {key, value} <- data_map, into: %{} do
        {to_string(key), value}
      end

    attrs = %{
      data: string_key_data
    }

    %Question{}
    |> Question.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a question.
  `attrs` should contain the `data` field with a map representation of the processed question content.
  """
  def update_question(%Question{} = question, attrs) do
    question
    |> Question.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a question.
  """
  def delete_question(%Question{} = question) do
    Repo.delete(question)
  end

  @doc """
  Imports a list of questions from a JSON string.

  Questions are created within a transaction. If any question fails to import,
  the entire transaction is rolled back.

  If `question_set_id` is provided and valid, all successfully imported questions
  will be added to that question set with sequential positions.
  `user_id` is used to authorize adding questions to a set. If `user_id` is nil,
  only ownerless (system) question sets can be modified.
  """
  def import_questions_from_json(json_string, user_id \\ nil, question_set_id \\ nil)
      when is_binary(json_string) and
             (is_nil(user_id) or is_integer(user_id)) and
             (is_nil(question_set_id) or is_integer(question_set_id)) do
    with {:ok, raw_list} <- Jason.decode(json_string),
         true <- is_list(raw_list) do
      processed_contents =
        Enum.map(raw_list, fn item ->
          try do
            import_struct = JsonSerializer.map_to_import_struct(item)
            Converter.to_processed_content(import_struct)
          rescue
            error ->
              {:error, "Failed to process item: #{inspect(error)}"}
          end
        end)

      failed_conversions = Enum.filter(processed_contents, &match?({:error, _}, &1))

      if length(failed_conversions) > 0 do
        {:error, :invalid_question_data, failed_conversions}
      else
        Repo.transaction(fn ->
          imported_questions =
            Enum.with_index(processed_contents)
            |> Enum.map(fn {content, index} ->
              case create_question(content) do
                {:ok, question} ->
                  question

                {:error, changeset} ->
                  Repo.rollback(
                    "Failed to import question at index #{index}: #{inspect(changeset.errors)}"
                  )
              end
            end)

          if question_set_id do
            case get_question_set(question_set_id) do
              nil ->
                Repo.rollback("Question set with id #{question_set_id} not found.")

              question_set ->
                can_add_to_set =
                  case {user_id, question_set.owner_id} do
                    # Allow nil user to modify ownerless sets
                    {nil, nil} -> true
                    # User owns the set
                    {uid, uid} when not is_nil(uid) -> true
                    # All other cases are unauthorized
                    _ -> false
                  end

                unless can_add_to_set do
                  if user_id == nil do
                    Repo.rollback(
                      "Cannot add questions to owned question set #{question_set_id} without user authorization."
                    )
                  else
                    Repo.rollback(
                      "User #{user_id} not authorized to add questions to set #{question_set_id}."
                    )
                  end
                end

                question_data_for_assoc =
                  Enum.map(imported_questions, fn question ->
                    %{id: question.id, position: nil}
                  end)

                case add_questions_to_set_impl(
                       question_set,
                       question_data_for_assoc,
                       imported_questions
                     ) do
                  {:ok, _updated_set} ->
                    :ok

                  {:error, reason} ->
                    Repo.rollback("Failed to add questions to set: #{inspect(reason)}")
                end
            end
          else
            :ok
          end

          imported_questions
        end)
      end
    else
      {:error, error_from_jason_decode} ->
        {:error, :invalid_json_payload, error_from_jason_decode}

      false ->
        {:error, :invalid_format_expected_list}
    end
  end

  @doc """
  Lists all tags.
  """
  def list_tags do
    Repo.all(Tag)
  end

  @doc """
  Creates a tag.
  """
  def create_tag(attrs \\ %{}) do
    normalized_attrs =
      for {key, value} <- attrs, into: %{} do
        case key do
          key when is_binary(key) -> {String.to_atom(key), value}
          key when is_atom(key) -> {key, value}
        end
      end

    %Tag{}
    |> Tag.changeset(normalized_attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a tag by name, creating it if it doesn't exist.
  """
  def get_or_create_tag(name) when is_binary(name) do
    case Repo.get_by(Tag, name: name) do
      nil -> create_tag(%{name: name})
      tag -> {:ok, tag}
    end
  end

  @doc """
  Adds tags to a question set. `tag_names_or_ids` can be a list of tag names (strings) or tag IDs.
  New tags will be created if names are provided that don't exist.
  """
  def add_tags_to_question_set(%QuestionSet{} = question_set, tag_names_or_ids)
      when is_list(tag_names_or_ids) do
    question_set = Repo.preload(question_set, :tags)

    tags_to_associate =
      Enum.map(tag_names_or_ids, fn item ->
        case item do
          id when is_integer(id) ->
            Repo.get(Tag, id)

          name when is_binary(name) ->
            case get_or_create_tag(name) do
              {:ok, tag} -> tag
              _ -> nil
            end

          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    changeset =
      Ecto.Changeset.change(question_set, %{})
      |> Ecto.Changeset.put_assoc(
        :tags,
        (tags_to_associate ++ question_set.tags) |> Enum.uniq_by(& &1.id)
      )

    case Repo.update(changeset) do
      {:ok, updated_set} -> {:ok, Repo.preload(updated_set, :tags)}
      error -> error
    end
  end

  @doc """
  Removes tags from a question set. `tag_names_or_ids` can be a list of tag names (strings) or tag IDs.
  """
  def remove_tags_from_question_set(%QuestionSet{} = question_set, tag_names_or_ids)
      when is_list(tag_names_or_ids) do
    ids_to_remove =
      Enum.map(tag_names_or_ids, fn item ->
        case item do
          id when is_integer(id) -> id
          name when is_binary(name) -> Repo.get_by(Tag, name: name) |> then(&(&1 && &1.id))
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    current_tags = question_set.tags || Repo.preload(question_set, :tags).tags

    tags_to_keep = Enum.reject(current_tags, &(&1.id in ids_to_remove))

    changeset =
      Ecto.Changeset.change(question_set, %{})
      |> Ecto.Changeset.put_assoc(:tags, tags_to_keep)

    case Repo.update(changeset) do
      {:ok, updated_set} -> {:ok, Repo.preload(updated_set, :tags)}
      error -> error
    end
  end

  @doc """
  Returns a list of all answers for a specific question.
  """
  def list_answers_for_question(question_id) do
    Answer
    |> where([a], a.question_id == ^question_id)
    |> preload([:user])
    |> Repo.all()
  end

  @doc """
  Returns a list of all answers for a specific user.
  """
  def list_answers_for_user(user_id) do
    Answer
    |> where([a], a.user_id == ^user_id)
    |> preload([:question])
    |> Repo.all()
  end

  @doc """
  Gets a single answer by ID.
  """
  def get_answer(id) do
    Answer
    |> Repo.get(id)
    |> case do
      nil -> nil
      answer -> Repo.preload(answer, [:user, :question])
    end
  end

  @doc """
  Gets an answer for a specific user and question combination.
  """
  def get_user_answer(user_id, question_id) do
    Answer
    |> where([a], a.user_id == ^user_id and a.question_id == ^question_id)
    |> preload([:user, :question])
    |> Repo.one()
  end

  @doc """
  Gets all answers from a user for a list of questions efficiently.

  `questions` should be a list of Question structs (can be partial structs with just :id field).
  Returns a list of Answer structs with preloaded user and question associations.

  ## Examples

      iex> questions = [%Question{id: 1}, %Question{id: 2}, %Question{id: 3}]
      iex> get_user_answers_for_questions(user_id, questions)
      [%Answer{...}, %Answer{...}]
  """
  def get_user_answers_for_questions(user_id, questions) when is_list(questions) do
    question_ids =
      questions
      |> Enum.map(fn
        %Question{id: id} -> id
        %{id: id} -> id
        id when is_integer(id) -> id
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)

    if Enum.empty?(question_ids) do
      []
    else
      Answer
      |> where([a], a.user_id == ^user_id and a.question_id in ^question_ids)
      |> preload([:user, :question])
      |> Repo.all()
    end
  end

  @doc """
  Gets user answers for questions with minimal data (no preloading).
  Only returns answer data + question_id, avoiding N+1 queries.
  Much faster for large question sets.

  ## Examples

      iex> questions = [%Question{id: 1}, %Question{id: 2}]
      iex> get_user_answers_for_questions_minimal(user_id, questions)
      [%Answer{question_id: 1, data: %{...}}, %Answer{question_id: 2, data: %{...}}]
  """
  def get_user_answers_for_questions_minimal(user_id, questions) when is_list(questions) do
    question_ids =
      questions
      |> Enum.map(fn
        %Question{id: id} -> id
        %{id: id} -> id
        id when is_integer(id) -> id
        _ -> nil
      end)
      |> Enum.reject(&is_nil/1)

    if Enum.empty?(question_ids) do
      []
    else
      Answer
      |> where([a], a.user_id == ^user_id and a.question_id in ^question_ids)
      |> select([a], %{
        id: a.id,
        question_id: a.question_id,
        data: a.data,
        is_correct: a.is_correct,
        user_id: a.user_id,
        inserted_at: a.inserted_at,
        updated_at: a.updated_at
      })
      |> Repo.all()
    end
  end

  @doc """
  Creates an answer.
  """
  def create_answer(attrs \\ %{}) do
    %Answer{}
    |> Answer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an answer.
  """
  def update_answer(%Answer{} = answer, attrs) do
    answer
    |> Answer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Creates or updates an answer for a user-question combination.
  If an answer already exists, it updates it. Otherwise, it creates a new one.
  """
  def upsert_answer(user_id, question_id, answer_data, is_correct \\ 2) do
    case get_user_answer(user_id, question_id) do
      nil ->
        create_answer(%{
          user_id: user_id,
          question_id: question_id,
          data: answer_data,
          is_correct: is_correct
        })

      existing_answer ->
        update_answer(existing_answer, %{
          data: answer_data,
          is_correct: is_correct
        })
    end
  end

  @doc """
  Deletes an answer.
  """
  def delete_answer(%Answer{} = answer) do
    Repo.delete(answer)
  end

  @doc """
  Gets answer statistics for a user.
  Returns a map with total_answers, correct_answers, incorrect_answers, and unevaluated_answers.
  """
  def get_user_answer_stats(user_id) do
    stats_query =
      from a in Answer,
        where: a.user_id == ^user_id,
        group_by: a.is_correct,
        select: {a.is_correct, count(a.id)}

    stats = Repo.all(stats_query) |> Enum.into(%{})

    %{
      total_answers: Map.values(stats) |> Enum.sum(),
      correct_answers: Map.get(stats, 1, 0),
      incorrect_answers: Map.get(stats, 0, 0),
      unevaluated_answers: Map.get(stats, 2, 0)
    }
  end

  @doc """
  Gets answer statistics for a specific question.
  Returns a map with total_answers, correct_answers, incorrect_answers, and unevaluated_answers.
  """
  def get_question_answer_stats(question_id) do
    stats_query =
      from a in Answer,
        where: a.question_id == ^question_id,
        group_by: a.is_correct,
        select: {a.is_correct, count(a.id)}

    stats = Repo.all(stats_query) |> Enum.into(%{})

    %{
      total_answers: Map.values(stats) |> Enum.sum(),
      correct_answers: Map.get(stats, 1, 0),
      incorrect_answers: Map.get(stats, 0, 0),
      unevaluated_answers: Map.get(stats, 2, 0)
    }
  end

  @doc """
  Gets performance statistics for a user on a specific question set.
  Returns stats about the user's answers to questions in the given question set.
  """
  def get_user_question_set_stats(user_id, question_set_id) do
    stats_query =
      from a in Answer,
        join: q in Question,
        on: a.question_id == q.id,
        join: qs in assoc(q, :question_sets),
        where: a.user_id == ^user_id and qs.id == ^question_set_id,
        group_by: a.is_correct,
        select: {a.is_correct, count(a.id)}

    stats = Repo.all(stats_query) |> Enum.into(%{})

    %{
      total_answers: Map.values(stats) |> Enum.sum(),
      correct_answers: Map.get(stats, 1, 0),
      incorrect_answers: Map.get(stats, 0, 0),
      unevaluated_answers: Map.get(stats, 2, 0)
    }
  end

  @doc """
  Validates and checks if a processed answer is correct for a given question.

  Uses the typed Answer structs from Processed.Answer to ensure proper validation.
  Returns {:ok, is_correct} or {:error, reason}.
  """
  def check_answer_correctness(question_id, answer_data) when is_map(answer_data) do
    with {:ok, question} <- get_question_with_validation(question_id),
         {:ok, processed_question} <- get_processed_question_content(question),
         {:ok, processed_answer} <- validate_and_process_answer(answer_data, processed_question) do
      is_correct = evaluate_processed_answer_correctness(processed_question, processed_answer)
      {:ok, is_correct}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_question_with_validation(question_id) do
    case get_question(question_id) do
      nil -> {:error, :question_not_found}
      question -> {:ok, question}
    end
  end

  defp get_processed_question_content(question) do
    try do
      processed = Processed.Question.from_map(question.data)
      {:ok, processed}
    rescue
      _ -> {:error, :invalid_question_data}
    end
  end

  defp validate_and_process_answer(answer_data, processed_question) do
    try do
      # Ensure the answer type matches the question type
      question_type = processed_question.question_type
      answer_data_with_type = Map.put(answer_data, "answer_type", question_type)

      processed_answer = Processed.Answer.from_map(answer_data_with_type)

      # Additional validation based on question type
      case validate_answer_for_question_type(processed_answer, processed_question) do
        :ok -> {:ok, processed_answer}
        {:error, reason} -> {:error, reason}
      end
    rescue
      error -> {:error, {:answer_processing_failed, error}}
    end
  end

  defp validate_answer_for_question_type(answer, question) do
    case {answer, question} do
      {%Processed.Answer.McqSingleAnswer{selected_index: idx},
       %Processed.Question.McqSingle{options: options}} ->
        if idx >= 0 and idx < length(options) do
          :ok
        else
          {:error, :invalid_option_index}
        end

      {%Processed.Answer.McqMultiAnswer{selected_indices: indices},
       %Processed.Question.McqMulti{options: options}} ->
        if Enum.all?(indices, fn idx -> idx >= 0 and idx < length(options) end) do
          :ok
        else
          {:error, :invalid_option_indices}
        end

      {%Processed.Answer.ClozeAnswer{answers: answers},
       %Processed.Question.Cloze{answers: expected_answers}} ->
        if length(answers) == length(expected_answers) do
          :ok
        else
          {:error, :wrong_number_of_answers}
        end

      {%Processed.Answer.TrueFalseAnswer{}, %Processed.Question.TrueFalse{}} ->
        :ok

      {%Processed.Answer.WrittenAnswer{}, %Processed.Question.Written{}} ->
        :ok

      {%Processed.Answer.EmqAnswer{}, %Processed.Question.Emq{}} ->
        :ok

      _ ->
        {:error, :mismatched_answer_question_types}
    end
  end

  defp evaluate_processed_answer_correctness(question, answer) do
    case {question, answer} do
      {%Processed.Question.McqSingle{correct_index: correct_idx},
       %Processed.Answer.McqSingleAnswer{selected_index: selected_idx}} ->
        selected_idx == correct_idx

      {%Processed.Question.McqMulti{correct_indices: correct_indices},
       %Processed.Answer.McqMultiAnswer{selected_indices: selected_indices}} ->
        MapSet.new(selected_indices) == MapSet.new(correct_indices)

      {%Processed.Question.TrueFalse{is_correct_true: correct},
       %Processed.Answer.TrueFalseAnswer{selected: selected}} ->
        selected == correct

      {%Processed.Question.Cloze{answers: correct_answers},
       %Processed.Answer.ClozeAnswer{answers: user_answers}} ->
        normalized_user = Enum.map(user_answers, &String.downcase(String.trim(&1)))
        normalized_correct = Enum.map(correct_answers, &String.downcase(String.trim(&1)))
        normalized_user == normalized_correct

      {%Processed.Question.Emq{matches: correct_matches},
       %Processed.Answer.EmqAnswer{matches: user_matches}} ->
        MapSet.new(correct_matches) == MapSet.new(user_matches)

      {%Processed.Question.Written{}, %Processed.Answer.WrittenAnswer{}} ->
        # Written answers require manual grading
        false

      _ ->
        false
    end
  end

  @doc """
  Marks answers as correct or incorrect based on the question data.
  This is useful for automatically grading questions with known correct answers.
  Only updates answers that are currently unevaluated (is_correct = 2).
  """
  def auto_grade_answers(question_id) do
    question = get_question(question_id)

    if question do
      unevaluated_answers =
        from(a in Answer,
          where: a.question_id == ^question_id and a.is_correct == 2,
          preload: [:user]
        )
        |> Repo.all()

      Enum.each(unevaluated_answers, fn answer ->
        is_correct = evaluate_answer_correctness(question.data, answer.data)
        update_answer(answer, %{is_correct: if(is_correct, do: 1, else: 0)})
      end)

      {:ok, length(unevaluated_answers)}
    else
      {:error, :question_not_found}
    end
  end

  defp evaluate_answer_correctness(question_data, answer_data) do
    case question_data["question_type"] do
      "mcq_single" ->
        selected_index = answer_data["selected_index"]
        correct_index = question_data["correct_index"]
        selected_index == correct_index

      "mcq_multi" ->
        selected_indices = answer_data["selected_indices"] || []
        correct_indices = question_data["correct_indices"] || []
        MapSet.new(selected_indices) == MapSet.new(correct_indices)

      "true_false" ->
        selected = answer_data["selected"]
        correct = question_data["is_correct_true"]
        selected == correct

      "cloze" ->
        user_answers = answer_data["answers"] || []
        correct_answers = question_data["answers"] || []
        normalized_user = Enum.map(user_answers, &String.downcase(String.trim(&1)))
        normalized_correct = Enum.map(correct_answers, &String.downcase(String.trim(&1)))
        normalized_user == normalized_correct

      "emq" ->
        user_matches = answer_data["matches"] || []
        correct_matches = question_data["matches"] || []
        MapSet.new(user_matches) == MapSet.new(correct_matches)

      "written" ->
        false

      _ ->
        false
    end
  end

  @doc """
  Gets a question by ID and loads it into a processed content struct.
  """
  def get_question_as_processed(id) do
    case get_question(id) do
      nil ->
        nil

      question ->
        try do
          {:ok, Processed.Question.from_map(question.data)}
        rescue
          _ -> {:error, :invalid_question_data}
        end
    end
  end

  @doc """
  Searches questions by text content.
  Returns questions where the question text or instructions contains the search term (case insensitive).
  """
  def search_questions(search_term, limit \\ 50) do
    search_pattern = "%#{String.downcase(search_term)}%"

    Question
    |> where(
      [q],
      fragment("LOWER(?) LIKE ?", q.data["question_text"], ^search_pattern) or
        fragment("LOWER(?) LIKE ?", q.data["instructions"], ^search_pattern)
    )
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Advanced search for questions with FTS5 support, filters, and pagination.

  ## Parameters
  - query: Search query string
  - opts: Keyword list with:
    - cursor: Pagination cursor for infinite scroll
    - limit: Number of results per page (default: 20)
    - search_scope: List of fields to search [:all] | [:question_text, :options, :answers, :explanation, :retention_aid, :instructions, :premises]
    - case_sensitive: Boolean for case sensitivity (default: false)
    - sort_by: :relevance | :newest | :oldest (default: :relevance)
    - question_types: List of question types to filter by
    - difficulties: List of difficulties to filter by


  ## Returns
  Tuple {results, next_cursor, total_count} where results is a list of maps with:
  - question: Question struct
  - snippet: FTS5 snippet with highlights
  - highlights: Raw highlight data
  - rank: FTS5 rank score
  """
  def search_questions_advanced(query, opts \\ []) do
    cursor = Keyword.get(opts, :cursor)
    limit = Keyword.get(opts, :limit, 20)
    search_scope = Keyword.get(opts, :search_scope, [:all])
    case_sensitive = Keyword.get(opts, :case_sensitive, false)
    sort_by = Keyword.get(opts, :sort_by, :relevance)
    question_types = Keyword.get(opts, :question_types, [])
    difficulties = Keyword.get(opts, :difficulties, [])

    # Handle special "*" query for "search all"
    if query == "*" do
      search_all_questions(cursor, limit, sort_by, question_types, difficulties)
    else
      fts_search_questions(
        query,
        cursor,
        limit,
        search_scope,
        case_sensitive,
        sort_by,
        question_types,
        difficulties
      )
    end
  end

  defp fts_search_questions(
         query,
         cursor,
         limit,
         search_scope,
         case_sensitive,
         sort_by,
         question_types,
         difficulties
       ) do
    # Build FTS5 query with proper escaping
    fts_query = build_safe_fts_query(query, search_scope, case_sensitive)

    # Build base query with FTS5 search
    base_query = """
    WITH search_results AS (
      SELECT
        question_id,
        rank,
        snippet(questions_fts, -1, '<mark>', '</mark>', '...', 30) as snippet,
        highlight(questions_fts, -1, '<mark>', '</mark>') as highlight_data
      FROM questions_fts
      WHERE questions_fts MATCH ?
      ORDER BY rank
    )
    SELECT DISTINCT
      q.*,
      sr.rank,
      sr.snippet,
      sr.highlight_data
    FROM questions q
    INNER JOIN search_results sr ON q.id = sr.question_id
    """

    # Build count query to get total results
    count_query = """
    WITH search_results AS (
      SELECT DISTINCT question_id
      FROM questions_fts
      WHERE questions_fts MATCH ?
    )
    SELECT COUNT(DISTINCT q.id)
    FROM questions q
    INNER JOIN search_results sr ON q.id = sr.question_id
    """

    {query_sql, params} =
      apply_filters_and_pagination(
        base_query,
        [fts_query],
        cursor,
        limit,
        sort_by,
        question_types,
        difficulties
      )

    {count_sql, count_params} =
      apply_count_filters(
        count_query,
        [fts_query],
        question_types,
        difficulties
      )

    execute_search_query_with_count(query_sql, params, count_sql, count_params, limit)
  end

  defp search_all_questions(cursor, limit, sort_by, question_types, difficulties) do
    base_query = """
    SELECT DISTINCT
      q.*,
      0.0 as rank,
      '' as snippet,
      '' as highlight_data
    FROM questions q
    """

    # Build count query to get total results
    count_query = """
    SELECT COUNT(DISTINCT q.id)
    FROM questions q
    """

    {query_sql, params} =
      apply_filters_and_pagination(
        base_query,
        [],
        cursor,
        limit,
        sort_by,
        question_types,
        difficulties
      )

    {count_sql, count_params} =
      apply_count_filters(
        count_query,
        [],
        question_types,
        difficulties
      )

    execute_search_query_with_count(query_sql, params, count_sql, count_params, limit)
  end

  defp build_safe_fts_query(query, search_scope, case_sensitive) do
    search_query = if case_sensitive, do: query, else: String.downcase(query)

    # Split query into terms and escape each one safely
    terms = String.split(search_query, ~r/\s+/, trim: true)

    safe_terms =
      Enum.map(terms, fn term ->
        # For FTS5 safety, wrap each term in double quotes and escape internal quotes
        escaped_term = String.replace(term, "\"", "\"\"")

        # Add prefix search (*) to the last character if it doesn't end with punctuation
        if String.match?(term, ~r/[a-zA-Z0-9]$/) do
          "\"#{escaped_term}\"*"
        else
          "\"#{escaped_term}\""
        end
      end)

    # Join terms with AND
    inner_query = Enum.join(safe_terms, " AND ")

    # Apply column filtering if not searching all fields
    if :all in search_scope or search_scope == [] do
      inner_query
    else
      # For scoped searches, create separate column queries and combine with OR
      # Correct FTS5 syntax: column1:(query) OR column2:(query)
      column_queries = Enum.map(search_scope, fn column -> "#{column}:(#{inner_query})" end)
      Enum.join(column_queries, " OR ")
    end
  end

  defp apply_filters_and_pagination(
         base_query,
         base_params,
         cursor,
         limit,
         sort_by,
         question_types,
         difficulties
       ) do
    # Start building WHERE conditions
    conditions = []
    params = base_params

    # Check if this is an FTS search query (has search_results table)
    has_search_results = String.contains?(base_query, "search_results")

    # Add filters
    {conditions, params} = add_question_type_filter(conditions, params, question_types)
    {conditions, params} = add_difficulty_filter(conditions, params, difficulties)

    {conditions, params} =
      add_cursor_filter(conditions, params, cursor, sort_by, has_search_results)

    # Build WHERE clause
    where_clause =
      if Enum.empty?(conditions) do
        ""
      else
        "WHERE " <> Enum.join(conditions, " AND ")
      end

    # Build ORDER BY clause - use different column names for search_all vs FTS search
    order_clause =
      case sort_by do
        :relevance ->
          if has_search_results do
            "ORDER BY sr.rank DESC, q.id"
          else
            # No relevance ranking for search_all
            "ORDER BY q.id"
          end

        :newest ->
          "ORDER BY q.inserted_at DESC, q.id"

        :oldest ->
          "ORDER BY q.inserted_at ASC, q.id"

        _ ->
          if has_search_results do
            "ORDER BY sr.rank DESC, q.id"
          else
            "ORDER BY q.id"
          end
      end

    # Combine query parts
    full_query = """
    #{base_query}
    #{where_clause}
    #{order_clause}
    LIMIT ?
    """

    {full_query, params ++ [limit + 1]}
  end

  defp add_question_type_filter(conditions, params, []), do: {conditions, params}

  defp add_question_type_filter(conditions, params, types) do
    placeholders = Enum.map_join(types, ",", fn _ -> "?" end)
    condition = "q.type IN (#{placeholders})"
    {[condition | conditions], params ++ types}
  end

  defp add_difficulty_filter(conditions, params, []), do: {conditions, params}

  defp add_difficulty_filter(conditions, params, difficulties) do
    placeholders = Enum.map_join(difficulties, ",", fn _ -> "?" end)
    condition = "q.difficulty IN (#{placeholders})"
    {[condition | conditions], params ++ difficulties}
  end

  defp add_cursor_filter(conditions, params, nil, _sort_by, _has_search_results),
    do: {conditions, params}

  defp add_cursor_filter(conditions, params, cursor, sort_by, has_search_results) do
    case sort_by do
      :relevance ->
        if has_search_results do
          condition = "(sr.rank < ? OR (sr.rank = ? AND q.id > ?))"
          {[condition | conditions], params ++ [cursor, cursor, cursor]}
        else
          condition = "q.id > ?"
          {[condition | conditions], params ++ [cursor]}
        end

      :newest ->
        condition = "(q.inserted_at < ? OR (q.inserted_at = ? AND q.id > ?))"
        {[condition | conditions], params ++ [cursor, cursor, cursor]}

      :oldest ->
        condition = "(q.inserted_at > ? OR (q.inserted_at = ? AND q.id > ?))"
        {[condition | conditions], params ++ [cursor, cursor, cursor]}

      _ ->
        {conditions, params}
    end
  end

  defp apply_count_filters(base_query, base_params, question_types, difficulties) do
    # Start building WHERE conditions
    conditions = []
    params = base_params

    # Add filters (no cursor for count queries)
    {conditions, params} = add_question_type_filter(conditions, params, question_types)
    {conditions, params} = add_difficulty_filter(conditions, params, difficulties)

    # Build WHERE clause
    where_clause =
      if Enum.empty?(conditions) do
        ""
      else
        "WHERE " <> Enum.join(conditions, " AND ")
      end

    # Combine query parts
    full_query = """
    #{base_query}
    #{where_clause}
    """

    {full_query, params}
  end

  defp execute_search_query_with_count(query_sql, params, count_sql, count_params, limit) do
    try do
      # Execute both queries
      results = Repo.query!(query_sql, params)
      count_result = Repo.query!(count_sql, count_params)

      rows = results.rows

      total_count =
        case count_result.rows do
          [[count]] -> count
          _ -> 0
        end

      {results_to_return, has_more} =
        if length(rows) > limit do
          {Enum.take(rows, limit), true}
        else
          {rows, false}
        end

      # Convert rows to result maps
      search_results =
        Enum.map(results_to_return, fn row ->
          [id, data, difficulty, type, inserted_at, updated_at, rank, snippet, highlight_data] =
            row

          question = %Question{
            id: id,
            data: Jason.decode!(data || "{}"),
            difficulty: difficulty,
            type: type,
            inserted_at: inserted_at,
            updated_at: updated_at
          }

          # Parse highlight data
          highlights =
            if highlight_data && highlight_data != "" do
              try do
                Jason.decode!(highlight_data)
              rescue
                _ -> %{}
              end
            else
              %{}
            end

          %{
            question: question,
            snippet: snippet || "",
            highlights: highlights,
            rank: rank || 0.0
          }
        end)

      # Calculate next cursor
      next_cursor =
        if has_more and not Enum.empty?(search_results) do
          last_result = List.last(search_results)

          case last_result do
            %{rank: rank} when rank != 0.0 -> rank
            %{question: %{id: id}} -> id
            _ -> nil
          end
        else
          nil
        end

      {search_results, next_cursor, total_count}
    rescue
      e ->
        Logger.error("Search query failed: #{inspect(e)}")
        {[], nil, 0}
    end
  end

  @doc """
  Gets question with answers for search results display.
  Similar to get_question but optimized for search results.
  """
  def get_question_for_search_display(question_id, user_id) do
    question = get_question(question_id)

    if question do
      user_answer = get_user_answer(user_id, question_id)

      %{
        question: question,
        user_answer: user_answer
      }
    else
      nil
    end
  end

  @doc """
  Searches questions that belong to specific question sets.
  Useful for searching within a user's owned or accessible sets.
  """
  def search_questions_in_sets(query, question_set_ids, opts \\ []) do
    opts = Keyword.put(opts, :question_set_ids, question_set_ids)
    search_questions_advanced(query, opts)
  end

  @doc """
  Lists questions by difficulty level.
  """
  def list_questions_by_difficulty(difficulty) do
    Question
    |> where([q], q.difficulty == ^difficulty)
    |> Repo.all()
  end

  @doc """
  Lists questions by type.
  """
  def list_questions_by_type(type) do
    Question
    |> where([q], q.type == ^type)
    |> Repo.all()
  end

  @doc """
  Gets questions that belong to a specific question set with their positions.
  Returns questions ordered by their position in the set.
  """
  def get_question_set_questions_with_positions(question_set_id) do
    from(q in Question,
      join: qsj in "question_set_questions",
      on: q.id == qsj.question_id,
      where: qsj.question_set_id == ^question_set_id,
      order_by: qsj.position,
      select: %{question: q, position: qsj.position}
    )
    |> Repo.all()
  end

  @doc """
  Updates the position of questions in a question set.
  `question_positions` should be a list of maps with :question_id and :position keys.
  """
  def update_question_positions_in_set(question_set_id, question_positions) do
    Repo.transaction(fn ->
      Enum.with_index(question_positions, fn %{question_id: question_id}, index ->
        from(qsj in "question_set_questions",
          where: qsj.question_set_id == ^question_set_id and qsj.question_id == ^question_id
        )
        |> Repo.update_all(set: [position: -(index + 1000)])
      end)

      Enum.each(question_positions, fn %{question_id: question_id, position: position} ->
        from(qsj in "question_set_questions",
          where: qsj.question_set_id == ^question_set_id and qsj.question_id == ^question_id
        )
        |> Repo.update_all(set: [position: position])
      end)
    end)
  end

  @doc """
  Gets questions that have not been answered by a specific user in a question set.
  """
  def get_unanswered_questions_for_user_in_set(user_id, question_set_id) do
    from(q in Question,
      join: qsj in "question_set_questions",
      on: q.id == qsj.question_id,
      left_join: a in Answer,
      on: q.id == a.question_id and a.user_id == ^user_id,
      where: qsj.question_set_id == ^question_set_id and is_nil(a.id),
      order_by: qsj.position
    )
    |> Repo.all()
  end

  @doc """
  Copies questions from one question set to another.
  Maintains the same positions if possible, or appends to the end if positions conflict.
  """
  def copy_questions_between_sets(source_set_id, target_set_id) do
    source_questions = get_question_set_questions_with_positions(source_set_id)
    target_set = get_question_set(target_set_id)

    if target_set do
      max_position_query =
        from(qsj in "question_set_questions",
          where: qsj.question_set_id == ^target_set_id,
          select: max(qsj.position)
        )

      max_position = Repo.one(max_position_query) || 0

      question_data_for_assoc =
        source_questions
        |> Enum.with_index()
        |> Enum.map(fn {%{question: question, position: _original_position}, index} ->
          %{id: question.id, position: max_position + index + 1}
        end)

      imported_questions = Enum.map(source_questions, & &1.question)

      add_questions_to_set_impl(target_set, question_data_for_assoc, imported_questions)
    else
      {:error, :target_set_not_found}
    end
  end

  def delete_user_answer(user_id, question_id) do
    case Repo.get_by(Answer, user_id: user_id, question_id: question_id) do
      nil ->
        {:ok, :not_found}

      answer ->
        Repo.delete(answer)
    end
  end

  @doc """
  Gets question sets accessible to a user (owned + public) with pagination and search.
  Returns {question_sets, total_count}.
  """
  def get_user_accessible_question_sets(
        user_id,
        search_query \\ "",
        page_number \\ 1,
        page_size \\ 15
      ) do
    offset = (page_number - 1) * page_size
    search_pattern = "%#{String.downcase(search_query)}%"

    # Subquery to count questions in each set
    question_count_subquery =
      from qsj in "question_set_questions",
        group_by: qsj.question_set_id,
        select: %{question_set_id: qsj.question_set_id, question_count: count(qsj.question_id)}

    base_query =
      from qs in QuestionSet,
        left_join: u in User,
        on: qs.owner_id == u.id,
        left_join: qc in subquery(question_count_subquery),
        on: qs.id == qc.question_set_id,
        where: qs.owner_id == ^user_id or not qs.is_private,
        preload: [:tags, :owner],
        select: %{
          question_set: qs,
          question_count: coalesce(qc.question_count, 0)
        }

    # Apply search filter if provided
    filtered_query =
      if search_query != "" do
        from [qs, u, qc] in base_query,
          where:
            fragment("LOWER(?) LIKE ?", qs.title, ^search_pattern) or
              fragment("LOWER(?) LIKE ?", qs.description, ^search_pattern)
      else
        base_query
      end

    # Get total count
    total_count =
      filtered_query
      |> exclude(:preload)
      |> exclude(:order_by)
      |> exclude(:select)
      |> select([qs, u, qc], count(qs.id))
      |> Repo.one()

    # Get paginated results
    results =
      filtered_query
      |> order_by([qs, u, qc], desc: qs.updated_at)
      |> limit(^page_size)
      |> offset(^offset)
      |> Repo.all()

    # Transform results to include question count in each question set
    question_sets =
      Enum.map(results, fn %{question_set: qs, question_count: count} ->
        Map.put(qs, :num_questions, count)
      end)

    {question_sets, total_count}
  end

  @doc """
  Gets questions that are not in a specific question set with pagination and search.
  Returns {questions, total_count}.
  """
  def get_questions_not_in_set(
        question_set_id,
        search_query \\ "",
        page_number \\ 1,
        page_size \\ 15
      ) do
    offset = (page_number - 1) * page_size
    search_pattern = "%#{String.downcase(search_query)}%"

    # Get IDs of questions already in the set
    questions_in_set_query =
      from qsj in "question_set_questions",
        where: qsj.question_set_id == ^question_set_id,
        select: qsj.question_id

    base_query =
      from q in Question,
        where: q.id not in subquery(questions_in_set_query)

    # Apply search filter if provided
    filtered_query =
      if search_query != "" do
        from q in base_query,
          where:
            fragment("LOWER(?) LIKE ?", q.data["question_text"], ^search_pattern) or
              fragment("LOWER(?) LIKE ?", q.data["instructions"], ^search_pattern)
      else
        base_query
      end

    # Get total count
    total_count =
      filtered_query
      |> Repo.aggregate(:count, :id)

    # Get paginated results
    questions =
      filtered_query
      |> order_by([q], desc: q.updated_at)
      |> limit(^page_size)
      |> offset(^offset)
      |> Repo.all()

    {questions, total_count}
  end

  @doc """
  Bulk deletes question sets owned by a user.
  Only deletes sets that are actually owned by the user for security.
  """
  def bulk_delete_question_sets(user_id, question_set_ids) when is_list(question_set_ids) do
    # Only delete sets owned by the user
    {count_deleted, _} =
      from(qs in QuestionSet,
        where: qs.id in ^question_set_ids and qs.owner_id == ^user_id
      )
      |> Repo.delete_all()

    {:ok, count_deleted}
  end

  @doc """
  Quick creates a private question set with just a name.
  Used for the quick create functionality in modals.
  """
  def quick_create_question_set(%User{} = user, title) when is_binary(title) do
    attrs = %{
      title: String.trim(title),
      description: nil,
      is_private: true
    }

    create_question_set(user, attrs)
  end

  @doc """
  Gets question set IDs that contain a specific question.
  """
  def get_question_sets_containing_question(question_id) do
    from(qsj in "question_set_questions",
      where: qsj.question_id == ^question_id,
      select: qsj.question_set_id
    )
    |> Repo.all()
  end

  @doc """
  Gets question sets owned by a user with information about whether they contain a specific question.
  Returns a list of question set DTOs with contains_question boolean.
  Includes pagination and search support.
  """
  def get_owned_question_sets_with_containing_information_for_question(
        user_id,
        question_id,
        search_query \\ "",
        page_number \\ 1,
        page_size \\ 15
      ) do
    offset = (page_number - 1) * page_size
    search_pattern = "%#{String.downcase(search_query)}%"

    base_query =
      from qs in QuestionSet,
        left_join: qsj in "question_set_questions",
        on: qs.id == qsj.question_set_id and qsj.question_id == ^question_id,
        where: qs.owner_id == ^user_id,
        preload: [:tags, :owner]

    # Apply search filter if provided
    filtered_query =
      if search_query != "" do
        from qs in base_query,
          where:
            fragment("LOWER(?) LIKE ?", qs.title, ^search_pattern) or
              fragment("LOWER(?) LIKE ?", qs.description, ^search_pattern)
      else
        base_query
      end

    # Get total count
    total_count =
      filtered_query
      |> exclude(:preload)
      |> exclude(:order_by)
      |> Repo.aggregate(:count, :id)

    # Get paginated results with containment information
    question_sets =
      filtered_query
      |> select([qs, qsj], %{question_set: qs, contains_question: not is_nil(qsj.question_id)})
      |> order_by([qs, qsj], desc: qs.updated_at)
      |> limit(^page_size)
      |> offset(^offset)
      |> Repo.all()

    {question_sets, total_count}
  end

  @doc """
  Modifies question-set relationships for a specific question.

  ## Parameters
  - `user_id`: ID of the user performing the operation (only user's owned sets can be modified)
  - `question_id`: ID of the question to modify
  - `set_modifications`: List of `{question_set_id, should_contain}` tuples where:
    - `question_set_id` is the ID of the question set
    - `should_contain` is a boolean indicating if the question should be in that set

  ## Returns
  - `{:ok, %{added_to_sets: count, removed_from_sets: count, total_modified: count, modified_sets: list}}` on success
  - `{:error, reason}` on failure

  Only modifies sets owned by the user for security.
  """
  def modify_question_sets(user_id, question_id, set_modifications)
      when is_list(set_modifications) do
    current_set_ids = MapSet.new(get_question_sets_containing_question(question_id))

    owned_sets =
      from(qs in QuestionSet,
        where: qs.owner_id == ^user_id,
        select: qs.id
      )
      |> Repo.all()
      |> MapSet.new()

    {sets_to_add, sets_to_remove} =
      set_modifications
      |> Enum.filter(fn {set_id, _should_contain} -> MapSet.member?(owned_sets, set_id) end)
      |> Enum.reduce({[], []}, fn {set_id, should_contain}, {adds, removes} ->
        currently_contains = MapSet.member?(current_set_ids, set_id)

        cond do
          should_contain and not currently_contains -> {[set_id | adds], removes}
          not should_contain and currently_contains -> {adds, [set_id | removes]}
          true -> {adds, removes}
        end
      end)

    Repo.transaction(fn ->
      add_results =
        Enum.map(sets_to_add, fn set_id ->
          case get_question_set(set_id) do
            nil ->
              {:error, :set_not_found}

            question_set ->
              case add_questions_to_set(question_set, [question_id], user_id) do
                {:ok, _} -> {:ok, {set_id, true}}
                error -> error
              end
          end
        end)

      remove_results =
        Enum.map(sets_to_remove, fn set_id ->
          case get_question_set(set_id) do
            nil ->
              {:error, :set_not_found}

            question_set ->
              case remove_questions_from_set(question_set, [question_id]) do
                {:ok, _} -> {:ok, {set_id, false}}
                error -> error
              end
          end
        end)

      add_successes = Enum.filter(add_results, &match?({:ok, _}, &1))
      add_failures = Enum.count(add_results, &match?({:error, _}, &1))

      remove_successes = Enum.filter(remove_results, &match?({:ok, _}, &1))
      remove_failures = Enum.count(remove_results, &match?({:error, _}, &1))

      if add_failures == 0 and remove_failures == 0 do
        modified_sets =
          Enum.map(add_successes ++ remove_successes, fn {:ok, {set_id, action}} ->
            %{set_id: set_id, action: action}
          end)

        %{
          added_to_sets: length(add_successes),
          removed_from_sets: length(remove_successes),
          total_modified: length(add_successes) + length(remove_successes),
          modified_sets: modified_sets
        }
      else
        Repo.rollback(%{
          add_successes: length(add_successes),
          add_failures: add_failures,
          remove_successes: length(remove_successes),
          remove_failures: remove_failures
        })
      end
    end)
  end

  @doc """
  Adds a question to multiple question sets.
  Only adds to sets owned by the user for security.
  """
  def add_question_to_multiple_sets(user_id, question_id, question_set_ids)
      when is_list(question_set_ids) do
    owned_sets =
      from(qs in QuestionSet,
        where: qs.id in ^question_set_ids and qs.owner_id == ^user_id,
        select: qs.id
      )
      |> Repo.all()

    results =
      Enum.map(owned_sets, fn set_id ->
        case get_question_set(set_id) do
          nil -> {:error, :set_not_found}
          question_set -> add_questions_to_set(question_set, [question_id], user_id)
        end
      end)

    successes = Enum.count(results, &match?({:ok, _}, &1))
    failures = Enum.count(results, &match?({:error, _}, &1))

    if failures == 0 do
      {:ok, %{added_to_sets: successes}}
    else
      {:error, %{added_to_sets: successes, failed_sets: failures}}
    end
  end

  @doc """
  Bulk adds multiple questions to a single question set.
  Only adds to sets owned by the user for security.
  """
  def bulk_add_questions_to_set(user_id, question_ids, question_set_id)
      when is_list(question_ids) do
    case get_question_set(question_set_id) do
      nil ->
        {:error, :set_not_found}

      question_set when question_set.owner_id != user_id ->
        {:error, :unauthorized}

      question_set ->
        add_questions_to_set(question_set, question_ids, user_id)
    end
  end

  @doc """
  Counts the number of questions in a question set.
  """
  def count_questions_in_set(question_set_id) do
    from(qsj in "question_set_questions",
      where: qsj.question_set_id == ^question_set_id,
      select: count(qsj.question_id)
    )
    |> Repo.one()
  end

  @doc """
  Gets a paginated list of questions from a question set.
  Returns questions ordered by their position in the set.
  """
  def get_question_set_questions_paginated(question_set_id, page \\ 1, page_size \\ 20) do
    offset = (page - 1) * page_size

    from(q in Question,
      join: qsj in "question_set_questions",
      on: q.id == qsj.question_id,
      where: qsj.question_set_id == ^question_set_id,
      order_by: qsj.position,
      limit: ^page_size,
      offset: ^offset
    )
    |> Repo.all()
  end

  @doc """
  Gets a chunk of questions from a question set for streaming/progressive loading.
  Returns questions ordered by their position in the set.
  """
  def get_question_set_questions_chunk(question_set_id, offset \\ 0, chunk_size \\ 30) do
    from(q in Question,
      join: qsj in "question_set_questions",
      on: q.id == qsj.question_id,
      where: qsj.question_set_id == ^question_set_id,
      order_by: qsj.position,
      limit: ^chunk_size,
      offset: ^offset
    )
    |> Repo.all()
  end

  @doc """
  Gets questions from a question set with optional search and filtering.
  Supports pagination for large question sets.
  """
  def get_question_set_questions_filtered(question_set_id, opts \\ []) do
    search_query = Keyword.get(opts, :search, "")
    difficulty_range = Keyword.get(opts, :difficulty_range, [1, 5])
    page = Keyword.get(opts, :page, 1)
    page_size = Keyword.get(opts, :page_size, 20)

    offset = (page - 1) * page_size
    search_pattern = "%#{String.downcase(search_query)}%"

    base_query =
      from(q in Question,
        join: qsj in "question_set_questions",
        on: q.id == qsj.question_id,
        where: qsj.question_set_id == ^question_set_id,
        order_by: qsj.position
      )

    filtered_query =
      base_query
      |> add_search_filter(search_pattern, search_query)
      |> add_difficulty_filter(difficulty_range)

    # Get total count for pagination
    total_count = filtered_query |> exclude(:order_by) |> Repo.aggregate(:count, :id)
    total_pages = div(total_count + page_size - 1, page_size)

    # Get paginated results
    questions =
      filtered_query
      |> limit(^page_size)
      |> offset(^offset)
      |> Repo.all()

    {questions,
     %{
       page: page,
       page_size: page_size,
       total_pages: total_pages,
       total_count: total_count,
       has_next: page < total_pages,
       has_prev: page > 1
     }}
  end

  defp add_search_filter(query, _search_pattern, ""), do: query

  defp add_search_filter(query, search_pattern, _search_query) do
    from q in query,
      where:
        fragment("LOWER(?) LIKE ?", q.data["question_text"], ^search_pattern) or
          fragment("LOWER(?) LIKE ?", q.data["instructions"], ^search_pattern)
  end

  defp add_difficulty_filter(query, [min_diff, max_diff]) do
    from q in query,
      where:
        fragment("CAST(? AS INTEGER)", q.data["difficulty"]) >= ^min_diff and
          fragment("CAST(? AS INTEGER)", q.data["difficulty"]) <= ^max_diff
  end
end
