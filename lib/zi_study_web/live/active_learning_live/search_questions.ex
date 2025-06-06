defmodule ZiStudyWeb.ActiveLearningLive.SearchQuestions do
  use ZiStudyWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.active_learning flash={@flash} current_scope={@current_scope}>
      <.svelte name="pages/ActiveLearningSearchQuestions" socket={@socket} props={%{}} />
    </Layouts.active_learning>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
