defmodule ZiStudyWeb.ActiveLearningLive.QuestionSet do
  use ZiStudyWeb, :live_view

  alias ZiStudy.Questions

  def render(assigns) do
    ~H"""
    <Layouts.active_learning flash={@flash} current_scope={@current_scope}>
      <.svelte
        name="pages/ActiveLearningQuestionSet"
        socket={@socket}
        props={%{questionSet: @question_set}}
      />
    </Layouts.active_learning>
    """
  end

  def mount(params, _session, socket) do
    current_user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign(:question_set, get_question_set(params["id"], current_user.id))}
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
end
