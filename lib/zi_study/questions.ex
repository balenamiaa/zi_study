defmodule ZiStudy.Questions do
  @moduledoc """
  The Questions context.
  Provides functions for managing Questions, QuestionSets, and Tags.
  """

  import Ecto.Query, warn: false
  alias ZiStudy.Repo

  alias ZiStudy.Accounts.User
  alias ZiStudy.Questions.Question
  alias ZiStudy.Questions.QuestionSet
  alias ZiStudy.Questions.Tag

  alias ZiStudy.QuestionsOps.Converter
  alias ZiStudy.QuestionsOps.JsonSerializer
  alias ZiStudy.QuestionsOps.Processed

  @doc """
  Returns a list of all question sets.

  Optionally filters by `user_id` to return sets owned by the user or public sets.
  If `filter_private` is true, only public sets are returned. `filter_private` is ignored if `user_id` is not provided.
  """
  def list_question_sets(user_id \\ nil, filter_private \\ false) do
    QuestionSet
    |> (fn query ->
          if user_id do
            # if filter_private is true, show public (is_private == false)
            # if filter_private is false, show private (is_private == true)
            # so, is_private should be (not filter_private)
            from qs in query,
              where: qs.owner_id == ^user_id and qs.is_private == not (^filter_private)
          else
            # if no user_id, only public sets are returned, filter_private is ignored
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
    attrs_with_owner = Map.put(attrs, "owner_id", user.id)

    %QuestionSet{}
    |> QuestionSet.changeset(attrs_with_owner)
    |> Repo.insert()
  end

  @doc """
  Creates a question set without an owner.
  These sets are always public by default.
  """
  def create_question_set_ownerless(attrs \\ %{}) do
    attrs_normalized =
      attrs
      |> Map.put_new("owner_id", nil)
      |> Map.put_new("is_private", false)

    %QuestionSet{}
    |> QuestionSet.changeset(attrs_normalized)
    |> Repo.insert()
  end

  @doc """
  Updates a question set.
  """
  def update_question_set(%QuestionSet{} = question_set, attrs) do
    question_set
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
         imported_questions_structs
       ) do
    new_associations_with_join_data =
      Enum.map(question_data_for_assoc, fn %{id: q_id, position: pos} ->
        # Find the full question struct from the imported list
        question_struct = Enum.find(imported_questions_structs, &(&1.id == q_id))
        # Add the join data. This modification is temporary for the changeset.
        Map.put(question_struct, :question_set_questions_join, %{position: pos})
      end)

    # To truly "add" without losing existing questions, we need to combine them.
    current_question_set = Repo.preload(question_set, :questions)
    existing_associations = current_question_set.questions || []

    # Combine new associations with existing ones.
    all_associations_for_changeset = new_associations_with_join_data ++ existing_associations

    # Use an empty attrs map for changes via put_assoc
    changeset =
      QuestionSet.changeset(current_question_set, %{})
      |> Ecto.Changeset.put_assoc(:questions, all_associations_for_changeset)

    case Repo.update(changeset) do
      {:ok, updated_set} -> {:ok, Repo.preload(updated_set, :questions)}
      error -> error
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
    attrs = %{
      data: Processed.Question.to_map(processed_question_content)
      # type and difficulty are set by the Question changeset from the data map
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
  `user_id` is used to authorize adding questions to a set.
  """
  def import_questions_from_json(json_string, user_id, question_set_id \\ nil) do
    with {:ok, raw_list} <- Jason.decode(json_string),
         true <- is_list(raw_list) do
      import_structs = Enum.map(raw_list, &JsonSerializer.map_to_import_struct/1)

      processed_contents = Enum.map(import_structs, &Converter.to_processed_content/1)

      Repo.transaction(fn ->
        imported_questions =
          Enum.with_index(processed_contents)
          |> Enum.map(fn {content, index} ->
            case create_question(content) do
              {:ok, question} ->
                question

              {:error, changeset} ->
                # If a single question fails, roll back the entire transaction
                Repo.rollback(
                  "Failed to import question at index #{index}: #{inspect(changeset.errors)}"
                )
            end
          end)

        # If question_set_id is provided, add imported questions to the set
        if question_set_id do
          case get_question_set(question_set_id) do
            nil ->
              Repo.rollback("Question set with id #{question_set_id} not found.")

            question_set ->
              is_owner = question_set.owner_id == user_id

              # Can add more conditions in the future if needed
              can_add_to_set = is_owner

              unless can_add_to_set do
                Repo.rollback(
                  "User #{user_id} not authorized to add questions to set #{question_set_id}."
                )
              end

              # Prepare question IDs with positions for adding to the set
              # Positions are 1-based for the newly imported questions within this batch
              question_data_for_assoc =
                Enum.with_index(imported_questions, fn question, index ->
                  %{id: question.id, position: index + 1}
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

        {:ok, imported_questions}
      end)
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
    %Tag{}
    |> Tag.changeset(attrs)
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
    tags_to_associate =
      Enum.map(tag_names_or_ids, fn item ->
        case item do
          id when is_integer(id) ->
            Repo.get(Tag, id)

          name when is_binary(name) ->
            case get_or_create_tag(name) do
              {:ok, tag} -> tag
              # Error creating tag, skip
              _ -> nil
            end

          # Invalid item, skip
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
end
