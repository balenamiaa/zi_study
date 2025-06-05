defmodule ZiStudyWeb.ActiveLearningLive.QuestionSet do
  use ZiStudyWeb, :live_view

  alias ZiStudy.Questions

  @default_page_size 15

  def render(assigns) do
    ~H"""
    <Layouts.active_learning flash={@flash} current_scope={@current_scope}>
      <.svelte
        name="pages/ActiveLearningQuestionSet"
        socket={@socket}
        props={
          %{
            questionSet: @question_set,
            userQuestionSets: @user_question_sets,
            currentUser: @current_user_dto
          }
        }
      />
    </Layouts.active_learning>
    """
  end

  def mount(params, _session, socket) do
    current_user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign(:question_set, get_question_set(params["id"], current_user.id))
     |> assign(:current_user_dto, owner_to_dto(current_user))
     |> assign(:user_question_sets, nil)}
  end

  def get_question_set(question_set_id, user_id) do
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

  defp question_set_to_accessible_dto(question_set, user_id) do
    %{
      id: question_set.id,
      title: question_set.title,
      description: question_set.description,
      is_private: question_set.is_private,
      is_owned: question_set.owner_id == user_id,
      owner: owner_to_dto(question_set.owner),
      tags: Enum.map(question_set.tags, fn tag -> %{id: tag.id, name: tag.name} end),
      inserted_at: question_set.inserted_at,
      updated_at: question_set.updated_at
    }
  end

  def get_tag_dto(tag) do
    %{
      id: tag.id,
      name: tag.name
    }
  end

  def get_question_dto(question) do
    %{
      id: question.id,
      data: question.data,
      inserted_at: question.inserted_at,
      updated_at: question.updated_at
    }
  end

  def owner_to_dto(owner) when is_map(owner) do
    %{
      email: owner.email
    }
  end

  def owner_to_dto(owner) when is_nil(owner) do
    nil
  end

  def answer_to_dto(answer) do
    %{
      id: answer.id,
      question_id: answer.question_id,
      data: answer.data,
      is_correct: answer.is_correct
    }
  end

  def handle_event("clear_user_question_sets", _params, socket) do
    {:noreply, assign(socket, :user_question_sets, nil)}
  end

  def handle_event(
        "load_owned_question_sets_for_question",
        %{
          "question_id" => question_id,
          "page_number" => page_number,
          "search_query" => search_query
        },
        socket
      ) do
    current_user = socket.assigns.current_scope.user
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

    question_sets_data = %{
      "page_size" => @default_page_size,
      "page_number" => page_number,
      "total_pages" => total_pages,
      "total_items" => total_count,
      "items" => items
    }

    {:noreply, assign(socket, :user_question_sets, question_sets_data)}
  end

  def handle_event("answer_question", %{"question_id" => question_id, "answer" => answer}, socket) do
    current_user = socket.assigns.current_scope.user
    question_id_int = String.to_integer(question_id)

    question = Questions.get_question(question_id_int)

    case question do
      nil ->
        {:noreply, put_flash(socket, :error, "Question not found")}

      %{data: %{"question_type" => "written"}} ->
        case Questions.upsert_answer(current_user.id, question_id_int, answer, 2) do
          {:ok, _answer} ->
            updated_question_set =
              get_question_set(socket.assigns.question_set.id, current_user.id)

            {:noreply,
             socket
             |> assign(:question_set, updated_question_set)
             |> push_event("answer_submitted", %{question_id: question_id})}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to save answer")}
        end

      _ ->
        case Questions.check_answer_correctness(question_id_int, answer) do
          {:ok, is_correct} ->
            is_correct_int = if is_correct, do: 1, else: 0

            case Questions.upsert_answer(current_user.id, question_id_int, answer, is_correct_int) do
              {:ok, _answer} ->
                updated_question_set =
                  get_question_set(socket.assigns.question_set.id, current_user.id)

                {:noreply,
                 socket
                 |> assign(:question_set, updated_question_set)
                 |> push_event("answer_submitted", %{question_id: question_id})}

              {:error, _changeset} ->
                {:noreply, put_flash(socket, :error, "Failed to save answer")}
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

            {:noreply,
             socket
             |> put_flash(:error, error_message)
             |> push_event("answer_submitted", %{question_id: question_id})}
        end
    end
  end

  def handle_event(
        "self_evaluate_answer",
        %{"question_id" => question_id, "is_correct" => is_correct},
        socket
      ) do
    current_user = socket.assigns.current_scope.user
    question_id_int = String.to_integer(question_id)
    is_correct_int = if is_correct, do: 1, else: 0

    case Questions.get_user_answer(current_user.id, question_id_int) do
      nil ->
        {:noreply, put_flash(socket, :error, "Answer not found")}

      answer ->
        case Questions.update_answer(answer, %{is_correct: is_correct_int}) do
          {:ok, _updated_answer} ->
            updated_question_set =
              get_question_set(socket.assigns.question_set.id, current_user.id)

            {:noreply,
             socket
             |> assign(:question_set, updated_question_set)}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to update self-evaluation")}
        end
    end
  end

  def handle_event("clear_answer", %{"question_id" => question_id}, socket) do
    current_user = socket.assigns.current_scope.user
    question_id_int = String.to_integer(question_id)

    case Questions.delete_user_answer(current_user.id, question_id_int) do
      {:ok, _} ->
        updated_question_set = get_question_set(socket.assigns.question_set.id, current_user.id)

        {:noreply,
         socket
         |> assign(:question_set, updated_question_set)
         |> push_event("answer_reset", %{question_id: question_id})}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to clear answer")}
    end
  end

  def handle_event("update_question_set", %{"field" => field, "value" => value}, socket) do
    current_user = socket.assigns.current_scope.user
    question_set_id = socket.assigns.question_set.id

    # Get the actual question set from DB to verify ownership
    case Questions.get_question_set(question_set_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Question set not found")}

      question_set_db when question_set_db.owner_id != current_user.id ->
        {:noreply, put_flash(socket, :error, "You don't have permission to edit this set")}

      question_set_db ->
        update_attrs = %{String.to_atom(field) => value}

        case Questions.update_question_set(question_set_db, update_attrs) do
          {:ok, _updated_set} ->
            updated_question_set = get_question_set(question_set_id, current_user.id)

            {:noreply,
             socket
             |> assign(:question_set, updated_question_set)}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to update question set")}
        end
    end
  end

  def handle_event(
        "modify_question_sets",
        %{"question_id" => question_id, "question_set_modifications" => modifications},
        socket
      ) do
    current_user = socket.assigns.current_scope.user
    question_id_int = String.to_integer(question_id)

    set_modifications =
      Enum.map(modifications, fn %{"set_id" => set_id, "should_contain" => should_contain} ->
        {String.to_integer(set_id), should_contain}
      end)

    case Questions.modify_question_sets(current_user.id, question_id_int, set_modifications) do
      {:ok,
       %{
         added_to_sets: added,
         removed_from_sets: removed,
         total_modified: total,
         modified_sets: modified_sets
       }} ->
        message =
          cond do
            added > 0 and removed > 0 ->
              "Added to #{added} set(s), removed from #{removed} set(s)"

            added > 0 ->
              "Added to #{added} set(s)"

            removed > 0 ->
              "Removed from #{removed} set(s)"

            true ->
              "No changes made"
          end

        current_question_set_id = socket.assigns.question_set.id

        current_set_modified =
          Enum.any?(modified_sets, fn %{set_id: set_id} ->
            set_id == current_question_set_id
          end)

        updated_socket =
          if current_set_modified do
            updated_question_set = get_question_set(current_question_set_id, current_user.id)
            assign(socket, :question_set, updated_question_set)
          else
            socket
          end

        {:noreply,
         updated_socket
         |> push_event("question_sets_modified", %{
           total_modified: total,
           modified_sets: modified_sets
         })}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to modify question sets")}
    end
  end

  def handle_event(
        "add_question_to_sets",
        %{"question_id" => question_id, "question_set_ids" => question_set_ids},
        socket
      ) do
    current_user = socket.assigns.current_scope.user
    question_id_int = String.to_integer(question_id)
    question_set_id_ints = Enum.map(question_set_ids, &String.to_integer/1)

    case Questions.add_question_to_multiple_sets(
           current_user.id,
           question_id_int,
           question_set_id_ints
         ) do
      {:ok, %{added_to_sets: count}} ->
        {:noreply,
         socket
         |> push_event("question_added_to_sets", %{count: count})
         |> assign(:user_question_sets, nil)}

      {:error, %{added_to_sets: successes, failed_sets: failures}} ->
        message = "Added to #{successes} set(s), failed for #{failures} set(s)"
        {:noreply, put_flash(socket, :warning, message)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to add question to sets")}
    end
  end

  def handle_event("quick_create_question_set", %{"title" => title}, socket) do
    current_user = socket.assigns.current_scope.user

    case Questions.quick_create_question_set(current_user, title) do
      {:ok, _question_set} ->
        {:noreply,
         socket
         |> push_event("set_created", %{})
         |> assign(:user_question_sets, nil)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create question set")}
    end
  end

  def handle_event("load_all_tags", %{"search_query" => search_query}, socket) do
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

    tag_dtos = Enum.map(filtered_tags, &get_tag_dto/1)

    {:noreply, push_event(socket, "tags_loaded", %{tags: tag_dtos})}
  end

  def handle_event("create_tag", %{"name" => name}, socket) do
    case Questions.create_tag(%{name: name}) do
      {:ok, tag} ->
        {:noreply, push_event(socket, "tag_created", %{tag: get_tag_dto(tag)})}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create tag")}
    end
  end

  def handle_event("clear_tags", _params, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "add_tags_to_question_set",
        %{"question_set_id" => question_set_id, "tag_ids" => tag_ids},
        socket
      ) do
    current_user = socket.assigns.current_scope.user
    question_set_id_int = String.to_integer(question_set_id)
    tag_id_ints = Enum.map(tag_ids, &String.to_integer/1)

    case Questions.get_question_set(question_set_id_int) do
      nil ->
        {:noreply, put_flash(socket, :error, "Question set not found")}

      question_set_db when question_set_db.owner_id != current_user.id ->
        {:noreply, put_flash(socket, :error, "You don't have permission to edit this set")}

      question_set_db ->
        case Questions.add_tags_to_question_set(question_set_db, tag_id_ints) do
          {:ok, _updated_set} ->
            updated_question_set = get_question_set(question_set_id_int, current_user.id)

            {:noreply,
             socket
             |> assign(:question_set, updated_question_set)}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to add tags")}
        end
    end
  end

  def handle_event(
        "remove_tags_from_question_set",
        %{"question_set_id" => question_set_id, "tag_ids" => tag_ids},
        socket
      ) do
    current_user = socket.assigns.current_scope.user
    question_set_id_int = String.to_integer(question_set_id)
    tag_id_ints = Enum.map(tag_ids, &String.to_integer/1)

    case Questions.get_question_set(question_set_id_int) do
      nil ->
        {:noreply, put_flash(socket, :error, "Question set not found")}

      question_set_db when question_set_db.owner_id != current_user.id ->
        {:noreply, put_flash(socket, :error, "You don't have permission to edit this set")}

      question_set_db ->
        case Questions.remove_tags_from_question_set(question_set_db, tag_id_ints) do
          {:ok, _updated_set} ->
            updated_question_set = get_question_set(question_set_id_int, current_user.id)

            {:noreply,
             socket
             |> assign(:question_set, updated_question_set)}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to remove tags")}
        end
    end
  end
end
