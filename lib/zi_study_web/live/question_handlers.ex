defmodule ZiStudyWeb.Live.QuestionHandlers do
  @moduledoc """
  Shared handlers for question-related LiveView events.
  Reduces duplication between question_set.ex and search_questions.ex.
  """

  alias ZiStudy.Questions

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
end
