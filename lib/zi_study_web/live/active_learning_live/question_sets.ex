defmodule ZiStudyWeb.ActiveLearningLive.QuestionSets do
  use ZiStudyWeb, :live_view

  alias ZiStudyWeb.Live.ActiveLearning.QuestionHandlers
  alias ZiStudyWeb.Live.ActiveLearning.QuestionSetsHandlers

  def render(assigns) do
    ~H"""
    <Layouts.active_learning flash={@flash} current_scope={@current_scope}>
      <.svelte
        name="pages/ActiveLearningQuestionSets"
        socket={@socket}
        props={
          %{
            questionSets: @question_sets,
            availableTags: @available_tags,
            currentUser: @current_user
          }
        }
      />
    </Layouts.active_learning>
    """
  end

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign(:question_sets, QuestionSetsHandlers.get_question_sets_with_stats(current_user.id))
     |> assign(:available_tags, QuestionSetsHandlers.get_available_tags())
     |> assign(:current_user, QuestionHandlers.owner_to_dto(current_user))}
  end

  def handle_event("create_question_set", params, socket) do
    current_user = socket.assigns.current_scope.user

    case QuestionSetsHandlers.handle_create_question_set(params, current_user) do
      {:ok, _question_set} ->
        {:noreply,
         socket
         |> assign(:question_sets, QuestionSetsHandlers.get_question_sets_with_stats(current_user.id))
         |> assign(:available_tags, QuestionSetsHandlers.get_available_tags())
         |> put_flash(:info, "Question set created successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create question set")}
    end
  end

  def handle_event("bulk_delete_question_sets", %{"question_set_ids" => question_set_ids}, socket) do
    current_user = socket.assigns.current_scope.user

    {:ok, count_deleted} = QuestionSetsHandlers.handle_bulk_delete_question_sets(question_set_ids, current_user)

    {:noreply,
     socket
     |> assign(:question_sets, QuestionSetsHandlers.get_question_sets_with_stats(current_user.id))
     |> assign(:available_tags, QuestionSetsHandlers.get_available_tags())
     |> put_flash(:info, "Deleted #{count_deleted} question set(s) successfully")}
  end
end
