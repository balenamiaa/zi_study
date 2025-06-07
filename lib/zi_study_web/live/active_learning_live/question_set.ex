defmodule ZiStudyWeb.ActiveLearningLive.QuestionSet do
  use ZiStudyWeb, :live_view

  alias ZiStudyWeb.Live.ActiveLearning.QuestionHandlers

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
     |> assign(:question_set, QuestionHandlers.get_question_set_with_answers(params["id"], current_user.id))
     |> assign(:current_user_dto, QuestionHandlers.owner_to_dto(current_user))
     |> assign(:user_question_sets, nil)}
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

    question_sets_data =
      QuestionHandlers.handle_load_owned_question_sets_for_question(
        question_id,
        page_number,
        search_query,
        current_user
      )

    {:noreply, assign(socket, :user_question_sets, question_sets_data)}
  end

  def handle_event("answer_question", %{"question_id" => question_id, "answer" => answer}, socket) do
    current_user = socket.assigns.current_scope.user

    case QuestionHandlers.handle_answer_question(question_id, answer, current_user) do
      {:ok, _answer_dto, event_data} ->
        updated_question_set =
          QuestionHandlers.get_question_set_with_answers(socket.assigns.question_set.id, current_user.id)

        {:noreply,
         socket
         |> assign(:question_set, updated_question_set)
         |> push_event("answer_submitted", event_data)}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}

      {:error, message, event_data} ->
        {:noreply,
         socket
         |> put_flash(:error, message)
         |> push_event("answer_submitted", event_data)}
    end
  end

  def handle_event(
        "self_evaluate_answer",
        %{"question_id" => question_id, "is_correct" => is_correct},
        socket
      ) do
    current_user = socket.assigns.current_scope.user

    case QuestionHandlers.handle_self_evaluate_answer(question_id, is_correct, current_user) do
      {:ok, _answer_dto} ->
        updated_question_set =
          QuestionHandlers.get_question_set_with_answers(socket.assigns.question_set.id, current_user.id)

        {:noreply, assign(socket, :question_set, updated_question_set)}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("clear_answer", %{"question_id" => question_id}, socket) do
    current_user = socket.assigns.current_scope.user

    case QuestionHandlers.handle_clear_answer(question_id, current_user) do
      {:ok, event_data} ->
        updated_question_set =
          QuestionHandlers.get_question_set_with_answers(socket.assigns.question_set.id, current_user.id)

        {:noreply,
         socket
         |> assign(:question_set, updated_question_set)
         |> push_event("answer_reset", event_data)}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("update_question_set", %{"field" => field, "value" => value}, socket) do
    current_user = socket.assigns.current_scope.user
    question_set_id = socket.assigns.question_set.id

    case QuestionHandlers.handle_update_question_set(question_set_id, field, value, current_user) do
      {:ok, _updated_set} ->
        updated_question_set =
          QuestionHandlers.get_question_set_with_answers(question_set_id, current_user.id)

        {:noreply, assign(socket, :question_set, updated_question_set)}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event(
        "modify_question_sets",
        %{"question_id" => question_id, "question_set_modifications" => modifications},
        socket
      ) do
    current_user = socket.assigns.current_scope.user
    current_question_set_id = socket.assigns.question_set.id

    case QuestionHandlers.handle_modify_question_sets(question_id, modifications, current_user) do
      {:ok, result} ->
        current_set_modified =
          Enum.any?(result.modified_sets, fn %{set_id: set_id} ->
            set_id == current_question_set_id
          end)

        updated_socket =
          if current_set_modified do
            updated_question_set =
              QuestionHandlers.get_question_set_with_answers(current_question_set_id, current_user.id)
            assign(socket, :question_set, updated_question_set)
          else
            socket
          end

        {:noreply,
         updated_socket
         |> push_event("question_sets_modified", %{
           total_modified: result.total_modified,
           modified_sets: result.modified_sets
         })}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event(
        "add_question_to_sets",
        %{"question_id" => question_id, "question_set_ids" => question_set_ids},
        socket
      ) do
    current_user = socket.assigns.current_scope.user

    case QuestionHandlers.handle_add_question_to_sets(question_id, question_set_ids, current_user) do
      {:ok, %{count: count}} ->
        {:noreply,
         socket
         |> push_event("question_added_to_sets", %{count: count})
         |> assign(:user_question_sets, nil)}

      {:error, message} ->
        {:noreply, put_flash(socket, :warning, message)}
    end
  end

  def handle_event("quick_create_question_set", %{"title" => title}, socket) do
    current_user = socket.assigns.current_scope.user

    case QuestionHandlers.handle_quick_create_question_set(title, current_user) do
      {:ok, _question_set} ->
        {:noreply,
         socket
         |> push_event("set_created", %{})
         |> assign(:user_question_sets, nil)}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("load_all_tags", %{"search_query" => search_query}, socket) do
    tag_dtos = QuestionHandlers.handle_load_tags(search_query)
    {:noreply, push_event(socket, "tags_loaded", %{tags: tag_dtos})}
  end

  def handle_event("create_tag", %{"name" => name}, socket) do
    case QuestionHandlers.handle_create_tag(name) do
      {:ok, tag_dto} ->
        {:noreply, push_event(socket, "tag_created", %{tag: tag_dto})}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
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

    case QuestionHandlers.handle_add_tags_to_question_set(question_set_id, tag_ids, current_user) do
      {:ok, _updated_set} ->
        question_set_id_int = String.to_integer(question_set_id)
        updated_question_set =
          QuestionHandlers.get_question_set_with_answers(question_set_id_int, current_user.id)

        {:noreply, assign(socket, :question_set, updated_question_set)}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event(
        "remove_tags_from_question_set",
        %{"question_set_id" => question_set_id, "tag_ids" => tag_ids},
        socket
      ) do
    current_user = socket.assigns.current_scope.user

    case QuestionHandlers.handle_remove_tags_from_question_set(question_set_id, tag_ids, current_user) do
      {:ok, _updated_set} ->
        question_set_id_int = String.to_integer(question_set_id)
        updated_question_set =
          QuestionHandlers.get_question_set_with_answers(question_set_id_int, current_user.id)

        {:noreply, assign(socket, :question_set, updated_question_set)}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end
end
