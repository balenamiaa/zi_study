defmodule ZiStudyWeb.Live.ActiveLearning.QuestionSetsHandlers do
  @moduledoc """
  Shared handlers for question sets-related LiveView events.
  Reduces duplication and provides reusable functions for question sets operations.
  """

  import Ecto.Query, warn: false
  alias ZiStudy.Questions
  alias ZiStudyWeb.Live.ActiveLearning.QuestionHandlers

  @doc """
  Gets question sets for a user with stats and formatted data.
  """
  def get_question_sets_with_stats(user_id) do
    question_sets_db =
      Questions.list_question_sets(user_id, false)
      |> ZiStudy.Repo.preload([:tags, :questions, :owner])

    Enum.map(question_sets_db, fn question_set ->
      %{
        id: question_set.id,
        title: question_set.title,
        description: question_set.description,
        is_private: question_set.is_private,
        owner: QuestionHandlers.owner_to_dto(question_set.owner),
        tags: Enum.map(question_set.tags, &QuestionHandlers.get_tag_dto/1),
        stats: Questions.get_user_question_set_stats(user_id, question_set.id),
        num_questions: length(question_set.questions),
        inserted_at: question_set.inserted_at,
        updated_at: question_set.updated_at
      }
    end)
  end

  @doc """
  Gets available tags formatted as DTOs.
  """
  def get_available_tags() do
    QuestionHandlers.get_available_tags()
  end

  @doc """
  Handles creating a new question set.
  """
  def handle_create_question_set(params, current_user) do
    %{"title" => title, "description" => description, "is_private" => is_private} = params

    attrs = %{
      title: title,
      description: if(description == "", do: nil, else: description),
      is_private: is_private
    }

    case Questions.create_question_set(current_user, attrs) do
      {:ok, question_set} ->
        {:ok, question_set}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Handles bulk deletion of question sets.
  """
  def handle_bulk_delete_question_sets(question_set_ids, current_user) do
    question_set_id_ints = Enum.map(question_set_ids, &String.to_integer/1)

    {:ok, count_deleted} =
      Questions.bulk_delete_question_sets(current_user.id, question_set_id_ints)

    {:ok, count_deleted}
  end

  @doc """
  Handles updating question set fields (title, description, is_private).
  Delegates to QuestionHandlers for the actual implementation.
  """
  def handle_update_question_set(question_set_id, field, value, current_user) do
    QuestionHandlers.handle_update_question_set(question_set_id, field, value, current_user)
  end

  @doc """
  Handles deleting a single question set.
  """
  def handle_delete_question_set(question_set_id, current_user_id) do
    case Questions.get_question_set(question_set_id) do
      nil ->
        {:error, "Question set not found"}

      question_set_db when question_set_db.owner_id != current_user_id ->
        {:error, "You don't have permission to delete this set"}

      question_set_db ->
        case Questions.delete_question_set(question_set_db) do
          {:ok, deleted_set} ->
            {:ok, deleted_set}

          {:error, _changeset} ->
            {:error, "Failed to delete question set"}
        end
    end
  end

  @doc """
  Handles adding tags to a question set.
  Delegates to QuestionHandlers for the actual implementation.
  """
  def handle_add_tags_to_question_set(question_set_id, tag_names_or_ids, current_user) do
    QuestionHandlers.handle_add_tags_to_question_set(
      question_set_id,
      tag_names_or_ids,
      current_user
    )
  end

  @doc """
  Handles removing tags from a question set.
  Delegates to QuestionHandlers for the actual implementation.
  """
  def handle_remove_tags_from_question_set(question_set_id, tag_names_or_ids, current_user) do
    QuestionHandlers.handle_remove_tags_from_question_set(
      question_set_id,
      tag_names_or_ids,
      current_user
    )
  end
end
