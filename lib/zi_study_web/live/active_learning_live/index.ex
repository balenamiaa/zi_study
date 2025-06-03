defmodule ZiStudyWeb.ActiveLearningLive.Index do
  use ZiStudyWeb, :live_view

  alias ZiStudy.Questions

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.svelte
        name="pages/ActiveLearningIndex"
        socket={@socket}
        props={%{questionSets: @question_sets}}
      />
    </Layouts.app>
    """
  end

  def mount(params, session, socket) do
    current_user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign(:question_sets, get_question_sets(current_user.id))}
  end

  def get_question_sets(user_id) do
    question_sets_db =
      Questions.list_question_sets() |> ZiStudy.Repo.preload([:tags, :questions, :owner])

    Enum.map(question_sets_db, fn question_set ->
      %{
        id: question_set.id,
        title: question_set.title,
        description: question_set.description,
        is_private: question_set.is_private,
        owner: owner_to_dto(question_set.owner),
        tags: Enum.map(question_set.tags, &get_tag_dto/1),
        stats: Questions.get_user_question_set_stats(user_id, question_set.id),
        inserted_at: question_set.inserted_at,
        updated_at: question_set.updated_at
      }
    end)
  end

  def get_tag_dto(tag) do
    %{
      id: tag.id,
      name: tag.name
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
end
