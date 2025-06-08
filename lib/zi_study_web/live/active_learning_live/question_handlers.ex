defmodule ZiStudyWeb.Live.ActiveLearning.QuestionHandlers do
  @moduledoc """
  Shared handlers for question-related LiveView events.
  Reduces duplication between question_set.ex and search_questions.ex.
  """

  import Ecto.Query, warn: false
  alias ZiStudy.Questions
  alias ZiStudy.Repo

  @default_page_size 15

  def answer_to_dto(answer) do
    %{
      id: answer.id,
      question_id: answer.question_id,
      data: answer.data,
      is_correct: answer.is_correct
    }
  end

  def handle_answer_question(question_id, answer, current_user) do
    question_id_int = String.to_integer(question_id)
    question = Questions.get_question(question_id_int)

    case question do
      nil ->
        {:error, "Question not found"}

      %{data: %{"question_type" => "written"}} ->
        case Questions.upsert_answer(current_user.id, question_id_int, answer, 2) do
          {:ok, answer} ->
            {:ok, answer_to_dto(answer), %{question_id: question_id}}

          {:error, _changeset} ->
            {:error, "Failed to save answer"}
        end

      _ ->
        case Questions.check_answer_correctness(question_id_int, answer) do
          {:ok, is_correct} ->
            is_correct_int = if is_correct, do: 1, else: 0

            case Questions.upsert_answer(current_user.id, question_id_int, answer, is_correct_int) do
              {:ok, answer} ->
                {:ok, answer_to_dto(answer), %{question_id: question_id}}

              {:error, _changeset} ->
                {:error, "Failed to save answer"}
            end

          {:error, reason} ->
            error_message =
              case reason do
                :question_not_found -> "Question not found"
                :invalid_question_data -> "Invalid question data"
                :invalid_option_index -> "Invalid option selected"
                :invalid_option_indices -> "Invalid options selected"
                :wrong_number_of_answers -> "Wrong number of answers provided"
                :mismatched_answer_question_types -> "Answer doesn't match question type"
                _ -> "Invalid answer format"
              end

            {:error, error_message, %{question_id: question_id}}
        end
    end
  end

  def handle_self_evaluate_answer(question_id, is_correct, current_user) do
    question_id_int = String.to_integer(question_id)
    is_correct_int = if is_correct, do: 1, else: 0

    case Questions.get_user_answer(current_user.id, question_id_int) do
      nil ->
        {:error, "Answer not found"}

      answer ->
        case Questions.update_answer(answer, %{is_correct: is_correct_int}) do
          {:ok, updated_answer} ->
            {:ok, answer_to_dto(updated_answer)}

          {:error, _changeset} ->
            {:error, "Failed to update self-evaluation"}
        end
    end
  end

  def handle_clear_answer(question_id, current_user) do
    question_id_int = String.to_integer(question_id)

    case Questions.delete_user_answer(current_user.id, question_id_int) do
      {:ok, _} ->
        {:ok, %{question_id: question_id}}

      {:error, _} ->
        {:error, "Failed to clear answer"}
    end
  end

  def handle_load_owned_question_sets_for_question(
        question_id,
        page_number,
        search_query,
        current_user
      ) do
    question_id_int = String.to_integer(question_id)

    {question_sets_with_info, total_count} =
      Questions.get_owned_question_sets_with_containing_information_for_question(
        current_user.id,
        question_id_int,
        search_query,
        page_number,
        @default_page_size
      )

    total_pages = div(total_count + @default_page_size - 1, @default_page_size)

    items =
      Enum.map(question_sets_with_info, fn %{question_set: qs, contains_question: contains} ->
        qs_dto = question_set_to_accessible_dto(qs, current_user.id)
        Map.put(qs_dto, :contains_question, contains)
      end)

    %{
      "page_size" => @default_page_size,
      "page_number" => page_number,
      "total_pages" => total_pages,
      "total_items" => total_count,
      "items" => items
    }
  end

  def handle_modify_question_sets(question_id, modifications, current_user) do
    question_id_int = String.to_integer(question_id)

    set_modifications =
      Enum.map(modifications, fn %{"set_id" => set_id, "should_contain" => should_contain} ->
        {String.to_integer(set_id), should_contain}
      end)

    case Questions.modify_question_sets(current_user.id, question_id_int, set_modifications) do
      {:ok, result} ->
        {:ok, result}

      {:error, _} ->
        {:error, "Failed to modify question sets"}
    end
  end

  def handle_quick_create_question_set(title, current_user) do
    case Questions.quick_create_question_set(current_user, title) do
      {:ok, question_set} ->
        {:ok, question_set}

      {:error, _changeset} ->
        {:error, "Failed to create question set"}
    end
  end

  def owner_to_dto(owner) when is_map(owner), do: %{email: owner.email}
  def owner_to_dto(nil), do: nil

  def get_tag_dto(tag) do
    %{id: tag.id, name: tag.name}
  end

  def get_question_dto(question) do
    %{
      id: question.id,
      data: question.data,
      difficulty: Map.get(question, :difficulty),
      type: Map.get(question, :type),
      inserted_at: question.inserted_at,
      updated_at: question.updated_at
    }
  end

  def question_set_to_accessible_dto(question_set, user_id) do
    %{
      id: question_set.id,
      title: question_set.title,
      description: question_set.description,
      is_private: question_set.is_private,
      is_owned: Map.get(question_set, :owner_id) == user_id,
      owner: owner_to_dto(question_set.owner),
      tags: Enum.map(question_set.tags, &get_tag_dto/1),
      num_questions: Map.get(question_set, :num_questions, 0),
      inserted_at: question_set.inserted_at,
      updated_at: question_set.updated_at
    }
  end

  def question_set_to_dto(question_set) do
    %{
      id: question_set.id,
      title: question_set.title,
      description: question_set.description,
      is_private: question_set.is_private,
      owner: owner_to_dto(question_set.owner),
      tags: Enum.map(question_set.tags, &get_tag_dto/1),
      num_questions:
        if(Map.has_key?(question_set, :questions), do: length(question_set.questions), else: nil),
      inserted_at: question_set.inserted_at,
      updated_at: question_set.updated_at
    }
  end

  def get_available_tags() do
    ZiStudy.Questions.list_tags()
    |> Enum.map(&get_tag_dto/1)
  end

  @doc """
  Bulk adds multiple questions to a single question set.
  Only adds to sets owned by the user for security.
  """
  def handle_bulk_add_questions_to_sets(user_id, question_ids, question_set_ids) when is_list(question_ids) and is_list(question_set_ids) do
    # Get all owned sets from the provided IDs
    owned_sets =
      from(qs in ZiStudy.Questions.QuestionSet,
        where: qs.id in ^question_set_ids and qs.owner_id == ^user_id
      )
      |> Repo.all()

    if Enum.empty?(owned_sets) do
      {:error, "No owned question sets found"}
    else
      results =
        Enum.map(owned_sets, fn question_set ->
          case ZiStudy.Questions.add_questions_to_set(question_set, question_ids, user_id) do
            {:ok, _updated_set} -> {:ok, question_set.id}
            {:ok, _updated_set, %{skipped_duplicates: count}} -> {:ok, question_set.id, %{skipped_duplicates: count}}
            {:error, reason} -> {:error, question_set.id, reason}
          end
        end)

      successes = Enum.filter(results, &match?({:ok, _}, &1) or match?({:ok, _, _}, &1))
      failures = Enum.filter(results, &match?({:error, _, _}, &1))

      total_skipped =
        successes
        |> Enum.map(fn
          {:ok, _, %{skipped_duplicates: count}} -> count
          _ -> 0
        end)
        |> Enum.sum()

      if Enum.empty?(failures) do
        {:ok, %{
          added_to_sets: length(successes),
          total_questions: length(question_ids),
          total_skipped_duplicates: total_skipped
        }}
      else
        {:error, %{
          added_to_sets: length(successes),
          failed_sets: length(failures),
          total_skipped_duplicates: total_skipped
        }}
      end
    end
  end

  @doc """
  Handles updating question set fields (title, description, is_private).
  """
  def handle_update_question_set(question_set_id, field, value, current_user) do
    case Questions.get_question_set(question_set_id) do
      nil ->
        {:error, "Question set not found"}

      question_set_db when question_set_db.owner_id != current_user.id ->
        {:error, "You don't have permission to edit this set"}

      question_set_db ->
        update_attrs = %{String.to_atom(field) => value}

        case Questions.update_question_set(question_set_db, update_attrs) do
          {:ok, updated_set} ->
            {:ok, updated_set}

          {:error, _changeset} ->
            {:error, "Failed to update question set"}
        end
    end
  end

  @doc """
  Handles adding question to multiple sets.
  """
  def handle_add_question_to_sets(question_id, question_set_ids, current_user) do
    question_id_int = String.to_integer(question_id)
    question_set_id_ints = Enum.map(question_set_ids, &String.to_integer/1)

    case Questions.add_question_to_multiple_sets(
           current_user.id,
           question_id_int,
           question_set_id_ints
         ) do
      {:ok, %{added_to_sets: count}} ->
        {:ok, %{count: count}}

      {:error, %{added_to_sets: successes, failed_sets: failures}} ->
        {:error, "Added to #{successes} set(s), failed for #{failures} set(s)"}

      {:error, _} ->
        {:error, "Failed to add question to sets"}
    end
  end

  @doc """
  Handles loading and filtering tags.
  """
  def handle_load_tags(search_query) do
    tags = Questions.list_tags()

    filtered_tags =
      if search_query != "" do
        search_pattern = String.downcase(search_query)

        Enum.filter(tags, fn tag ->
          String.contains?(String.downcase(tag.name), search_pattern)
        end)
      else
        tags
      end

    Enum.map(filtered_tags, &get_tag_dto/1)
  end

  @doc """
  Handles creating a new tag.
  """
  def handle_create_tag(name) do
    case Questions.create_tag(%{name: name}) do
      {:ok, tag} ->
        {:ok, get_tag_dto(tag)}

      {:error, _changeset} ->
        {:error, "Failed to create tag"}
    end
  end

  @doc """
  Handles adding tags to a question set.
  """
  def handle_add_tags_to_question_set(question_set_id, tag_names_or_ids, current_user) do
    question_set_id_int = if is_integer(question_set_id), do: question_set_id, else: String.to_integer(question_set_id)

    # Convert strings that look like integers to integers, keep other strings as tag names
    processed_tags = Enum.map(tag_names_or_ids, fn item ->
      case Integer.parse(item) do
        {int_val, ""} -> int_val  # It's a pure integer string
        _ -> item                 # It's a tag name
      end
    end)

    case Questions.get_question_set(question_set_id_int) do
      nil ->
        {:error, "Question set not found"}

      question_set_db when question_set_db.owner_id != current_user.id ->
        {:error, "You don't have permission to edit this set"}

      question_set_db ->
        case Questions.add_tags_to_question_set(question_set_db, processed_tags) do
          {:ok, updated_set} ->
            {:ok, updated_set}

          {:error, _changeset} ->
            {:error, "Failed to add tags"}
        end
    end
  end

  @doc """
  Handles removing tags from a question set.
  """
  def handle_remove_tags_from_question_set(question_set_id, tag_names_or_ids, current_user) do
    question_set_id_int = if is_integer(question_set_id), do: question_set_id, else: String.to_integer(question_set_id)

    # Convert strings that look like integers to integers, keep other strings as tag names
    processed_tags = Enum.map(tag_names_or_ids, fn item ->
      case Integer.parse(item) do
        {int_val, ""} -> int_val  # It's a pure integer string
        _ -> item                 # It's a tag name
      end
    end)

    case Questions.get_question_set(question_set_id_int) do
      nil ->
        {:error, "Question set not found"}

      question_set_db when question_set_db.owner_id != current_user.id ->
        {:error, "You don't have permission to edit this set"}

      question_set_db ->
        case Questions.remove_tags_from_question_set(question_set_db, processed_tags) do
          {:ok, updated_set} ->
            {:ok, updated_set}

          {:error, _changeset} ->
            {:error, "Failed to remove tags"}
        end
    end
  end

  @doc """
  Gets a question set with full data including answers for a user.
  """
  def get_question_set_with_answers(question_set_id, user_id) do
    question_set_db =
      Questions.get_question_set(question_set_id)
      |> ZiStudy.Repo.preload([:tags, :questions, :owner])

    %{
      id: question_set_db.id,
      title: question_set_db.title,
      description: question_set_db.description,
      is_private: question_set_db.is_private,
      owner: owner_to_dto(question_set_db.owner),
      tags: Enum.map(question_set_db.tags, &get_tag_dto/1),
      questions: Enum.map(question_set_db.questions, &get_question_dto/1),
      answers:
        Enum.map(
          Questions.get_user_answers_for_questions(user_id, question_set_db.questions),
          &answer_to_dto/1
        ),
      stats: Questions.get_user_question_set_stats(user_id, question_set_db.id),
      inserted_at: question_set_db.inserted_at,
      updated_at: question_set_db.updated_at
    }
  end

  @doc """
  Gets question set metadata without loading all questions.
  Much faster for large question sets.
  """
  def get_question_set_metadata(question_set_id, user_id) do
    question_set_db =
      Questions.get_question_set(question_set_id)
      |> ZiStudy.Repo.preload([:tags, :owner])

    %{
      id: question_set_db.id,
      title: question_set_db.title,
      description: question_set_db.description,
      is_private: question_set_db.is_private,
      owner: owner_to_dto(question_set_db.owner),
      tags: Enum.map(question_set_db.tags, &get_tag_dto/1),
      questions: [], # Will be loaded separately
      answers: [], # Will be loaded separately
      stats: Questions.get_user_question_set_stats(user_id, question_set_db.id),
      inserted_at: question_set_db.inserted_at,
      updated_at: question_set_db.updated_at
    }
  end

  @doc """
  Gets a paginated set of questions for a question set with their answers.
  Returns {questions_with_answers, pagination_info}.
  """
  def get_question_set_questions_page(question_set_id, user_id, page \\ 1, page_size \\ 20) do
    # Get total count of questions in the set
    total_questions = Questions.count_questions_in_set(question_set_id)
    total_pages = div(total_questions + page_size - 1, page_size)

    # Get paginated questions
    questions_page = Questions.get_question_set_questions_paginated(question_set_id, page, page_size)

    # Get answers for just these questions
    user_answers = Questions.get_user_answers_for_questions(user_id, questions_page)

    questions_dto = Enum.map(questions_page, &get_question_dto/1)
    answers_dto = Enum.map(user_answers, &answer_to_dto/1)

    pagination_info = %{
      page: page,
      page_size: page_size,
      total_pages: total_pages,
      total_questions: total_questions,
      has_next: page < total_pages,
      has_prev: page > 1
    }

    {%{questions: questions_dto, answers: answers_dto}, pagination_info}
  end

  @doc """
  Gets a chunk of questions for streaming/progressive loading.
  Returns {questions_chunk, loading_state_info}.
  """
  def get_question_set_questions_chunk(question_set_id, user_id, offset \\ 0, chunk_size \\ 30) do
    # Get total count of questions in the set (cached for subsequent calls)
    total_questions = Questions.count_questions_in_set(question_set_id)

    # Get the chunk of questions
    questions_chunk = Questions.get_question_set_questions_chunk(question_set_id, offset, chunk_size)

    # Get answers for just these questions
    user_answers = Questions.get_user_answers_for_questions(user_id, questions_chunk)

    questions_dto = Enum.map(questions_chunk, &get_question_dto/1)
    answers_dto = Enum.map(user_answers, &answer_to_dto/1)

    new_loaded_count = offset + length(questions_chunk)
    has_more = new_loaded_count < total_questions

    loading_state_info = %{
      loaded_count: new_loaded_count,
      total_count: total_questions,
      has_more: has_more
    }

    {%{questions: questions_dto, answers: answers_dto}, loading_state_info}
  end

  @doc """
  Gets initial chunk of questions for SSR with minimal size.
  Returns {questions_chunk, streaming_state}.
  """
  def get_initial_questions_chunk(question_set_id, user_id, initial_size \\ 10) do
    # Get total count once
    total_questions = Questions.count_questions_in_set(question_set_id)

    # Get initial chunk (first N questions)
    questions_chunk = Questions.get_question_set_questions_chunk(question_set_id, 0, initial_size)

    # Get answers for just these questions (optimized query)
    user_answers = Questions.get_user_answers_for_questions_minimal(user_id, questions_chunk)

    questions_dto = Enum.map(questions_chunk, &get_question_dto/1)
    answers_dto = Enum.map(user_answers, &answer_to_dto_minimal/1)

    streaming_state = %{
      loaded_count: length(questions_chunk),
      total_count: total_questions,
      has_more: length(questions_chunk) < total_questions,
      is_streaming: false
    }

    {%{questions: questions_dto, answers: answers_dto}, streaming_state}
  end

  @doc """
  Gets questions chunk for streaming (after initial load).
  """
  def get_questions_chunk(question_set_id, user_id, offset, chunk_size) do
    # Get the chunk of questions
    questions_chunk = Questions.get_question_set_questions_chunk(question_set_id, offset, chunk_size)

    # Get answers for just these questions (optimized)
    user_answers = Questions.get_user_answers_for_questions_minimal(user_id, questions_chunk)

    questions_dto = Enum.map(questions_chunk, &get_question_dto/1)
    answers_dto = Enum.map(user_answers, &answer_to_dto_minimal/1)

    new_loaded_count = offset + length(questions_chunk)

    # We need the total count - could cache this or pass it in
    total_questions = Questions.count_questions_in_set(question_set_id)
    has_more = new_loaded_count < total_questions

    streaming_state = %{
      loaded_count: new_loaded_count,
      total_count: total_questions,
      has_more: has_more,
      is_streaming: has_more  # Keep streaming if there's more
    }

    {%{questions: questions_dto, answers: answers_dto}, streaming_state}
  end

  @doc """
  Minimal answer DTO that doesn't include question preloading.
  """
  def answer_to_dto_minimal(answer) do
    %{
      id: answer.id,
      question_id: answer.question_id,
      data: answer.data,
      is_correct: answer.is_correct
    }
  end
end
