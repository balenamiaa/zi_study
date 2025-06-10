defmodule ZiStudyWeb.HomeLive do
  use ZiStudyWeb, :live_view
  alias ZiStudyWeb.Layouts

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">
        <section class="w-full py-6"></section>
        <section class="w-full py-6">
          <div class="w-full space-y-4">
            <h1 class="text-3xl font-bold">Welcome to ZiStudy</h1>

            <p class="text-lg text-base-content/70">
              What do I even put here? Go to 'Active Learning'.
            </p>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end
end
