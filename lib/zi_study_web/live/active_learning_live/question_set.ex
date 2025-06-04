defmodule ZiStudyWeb.ActiveLearningLive.QuestionSet do
  use ZiStudyWeb, :live_view

  alias ZiStudy.Questions

  def mount(params, _session, socket) do
    current_user = socket.assigns.current_scope.user

    {:ok,
     socket
     |> assign(:question_set, get_question_set(params["id"], current_user.id))}
  end

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
end
