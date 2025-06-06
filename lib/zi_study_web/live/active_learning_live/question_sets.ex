defmodule ZiStudyWeb.ActiveLearningLive.QuestionSets do
  use ZiStudyWeb, :live_view

  alias ZiStudy.Questions

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
     |> assign(:question_sets, get_question_sets(current_user.id))
     |> assign(:available_tags, get_available_tags())
     |> assign(:current_user, owner_to_dto(current_user))}
  end

  defp get_question_sets(user_id) do
    question_sets_db =
      Questions.list_question_sets(user_id, false)
      |> ZiStudy.Repo.preload([:tags, :questions, :owner])

    Enum.map(question_sets_db, fn question_set ->
      %{
        id: question_set.id,
        title: question_set.title,
        description: question_set.description,
        is_private: question_set.is_private,
        owner: owner_to_dto(question_set.owner),
        tags: Enum.map(question_set.tags, &get_tag_dto/1),
        stats: Questions.get_user_question_set_stats(user_id, question_set.id),
        num_questions: length(question_set.questions),
        inserted_at: question_set.inserted_at,
        updated_at: question_set.updated_at
      }
    end)
  end

  defp get_available_tags do
    Questions.list_tags()
    |> Enum.map(&get_tag_dto/1)
  end

  defp get_tag_dto(tag) do
    %{id: tag.id, name: tag.name}
  end

  defp owner_to_dto(owner) when is_map(owner), do: %{email: owner.email}
  defp owner_to_dto(nil), do: nil

  def handle_event("create_question_set", params, socket) do
    %{"title" => title, "description" => description, "is_private" => is_private} = params
    current_user = socket.assigns.current_scope.user

    attrs = %{
      title: title,
      description: if(description == "", do: nil, else: description),
      is_private: is_private
    }

    case Questions.create_question_set(current_user, attrs) do
      {:ok, _question_set} ->
        {:noreply,
         socket
         |> assign(:question_sets, get_question_sets(current_user.id))
         |> assign(:available_tags, get_available_tags())
         |> put_flash(:info, "Question set created successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create question set")}
    end
  end

  def handle_event("bulk_delete_question_sets", %{"question_set_ids" => question_set_ids}, socket) do
    current_user = socket.assigns.current_scope.user
    question_set_id_ints = Enum.map(question_set_ids, &String.to_integer/1)

    {:ok, count_deleted} =
      Questions.bulk_delete_question_sets(current_user.id, question_set_id_ints)

    {:noreply,
     socket
     |> assign(:question_sets, get_question_sets(current_user.id))
     |> assign(:available_tags, get_available_tags())
     |> put_flash(:info, "Deleted #{count_deleted} question set(s) successfully")}
  end
end
