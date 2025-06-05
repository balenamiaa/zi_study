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
            questions: @questions,
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
     |> assign(:user_question_sets, nil)
     |> assign(:questions, nil)}
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

  def handle_event(
        "load_user_question_sets",
        %{"page_number" => page_number, "search_query" => search_query},
        socket
      ) do
    current_user = socket.assigns.current_scope.user

    {user_question_sets, total_count} =
      Questions.get_user_accessible_question_sets(
        current_user.id,
        search_query,
        page_number,
        @default_page_size
      )

    total_pages = div(total_count + @default_page_size - 1, @default_page_size)

    {:noreply,
     assign(socket, :user_question_sets, %{
       "page_size" => @default_page_size,
       "page_number" => page_number,
       "total_pages" => total_pages,
       "total_items" => total_count,
       "items" =>
         user_question_sets |> Enum.map(&question_set_to_accessible_dto(&1, current_user.id))
     })}
  end

  def handle_event(
        "load_questions",
        %{"page_number" => page_number, "search_query" => search_query},
        socket
      ) do
    current_question_set = socket.assigns.question_set

    {questions, total_count} =
      Questions.get_questions_not_in_set(
        current_question_set.id,
        search_query,
        page_number,
        @default_page_size
      )

    total_pages = div(total_count + @default_page_size - 1, @default_page_size)

    {:noreply,
     assign(socket, :questions, %{
       "page_size" => @default_page_size,
       "page_number" => page_number,
       "total_pages" => total_pages,
       "total_items" => total_count,
       "items" => questions |> Enum.map(&get_question_dto/1)
     })}
  end

  def handle_event("clear_questions", _params, socket) do
    {:noreply, assign(socket, :questions, nil)}
  end

  def handle_event("clear_user_question_sets", _params, socket) do
    {:noreply, assign(socket, :user_question_sets, nil)}
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
             |> assign(:question_set, updated_question_set)
             |> put_flash(:info, "Question set updated successfully")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to update question set")}
        end
    end
  end

  def handle_event("add_questions_to_set", %{"question_ids" => question_ids}, socket) do
    current_user = socket.assigns.current_scope.user
    question_set_id = socket.assigns.question_set.id

    case Questions.get_question_set(question_set_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Question set not found")}

      question_set_db when question_set_db.owner_id != current_user.id ->
        {:noreply, put_flash(socket, :error, "You don't have permission to edit this set")}

      question_set_db ->
        question_id_ints = Enum.map(question_ids, &String.to_integer/1)

        case Questions.add_questions_to_set(question_set_db, question_id_ints, current_user.id) do
          {:ok, _updated_set} ->
            updated_question_set = get_question_set(question_set_id, current_user.id)

            {:noreply,
             socket
             |> assign(:question_set, updated_question_set)
             # Clear the questions list to refresh
             |> assign(:questions, nil)
             |> put_flash(:info, "Questions added successfully")}

          {:error, reason} ->
            error_message =
              case reason do
                :unauthorized -> "You don't have permission to edit this set"
                :no_valid_questions -> "No valid questions provided"
                _ -> "Failed to add questions"
              end

            {:noreply, put_flash(socket, :error, error_message)}
        end
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
         |> put_flash(:info, "Question added to #{count} set(s) successfully")
         # Clear to refresh
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
         |> put_flash(:info, "Question set '#{title}' created successfully")
         # Clear to refresh
         |> assign(:user_question_sets, nil)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create question set")}
    end
  end
end
