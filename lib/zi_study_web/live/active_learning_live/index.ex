defmodule ZiStudyWeb.ActiveLearningLive.Index do
  use ZiStudyWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, push_navigate(socket, to: ~p"/active-learning/question_sets")}
  end
end
