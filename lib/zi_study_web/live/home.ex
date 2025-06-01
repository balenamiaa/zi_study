defmodule ZiStudyWeb.HomeLive do
  use ZiStudyWeb, :live_view
  alias ZiStudyWeb.Layouts

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:startDateStr, "2025-01-01")
     |> assign(:endDateStr, "2025-06-01")}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">
        <section class="w-full py-6">
          <.svelte
            name="DatePicker"
            socket={@socket}
            props={
              %{
                startDateStr: @startDateStr,
                endDateStr: @endDateStr
              }
            }
          />
        </section>
        <section class="w-full py-6">
          <div class="w-full space-y-4">
            <h1 class="text-3xl font-bold">Welcome to ZiStudy</h1>

            <p class="text-lg text-base-content/70">
              These are just some random content.
            </p>
          </div>
        </section>

        <div class="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
          <div class="card bg-base-200 shadow-md hover:shadow-lg transition-all">
            <div class="card-body">
              <h2 class="card-title flex gap-2">
                <.icon name="hero-academic-cap-solid" class="size-5 text-primary" /> Some Stuff
              </h2>

              <p>Access high-quality learning materials tailored to your needs.</p>

              <div class="card-actions justify-end">
                <button class="btn btn-primary btn-sm">Get Started</button>
              </div>
            </div>
          </div>

          <div class="card bg-base-200 shadow-md hover:shadow-lg transition-all">
            <div class="card-body">
              <h2 class="card-title flex gap-2">
                <.icon name="hero-puzzle-piece-solid" class="size-5 text-primary" /> Practice
              </h2>

              <p>Reinforce your knowledge with interactive exercises and quizzes.</p>

              <div class="card-actions justify-end">
                <button class="btn btn-primary btn-sm">Try Now</button>
              </div>
            </div>
          </div>

          <div class="card bg-base-200 shadow-md hover:shadow-lg transition-all">
            <div class="card-body">
              <h2 class="card-title flex gap-2">
                <.icon name="hero-chart-bar-solid" class="size-5 text-primary" /> Track
              </h2>

              <p>Monitor your progress and celebrate your achievements.</p>

              <div class="card-actions justify-end">
                <button class="btn btn-primary btn-sm">View Stats</button>
              </div>
            </div>
          </div>
        </div>

        <section class="w-full py-6">
          <div class="card bg-base-200 shadow-md p-6">
            <h2 class="text-2xl font-bold mb-4">Getting Started</h2>

            <ul class="steps steps-vertical lg:steps-horizontal w-full">
              <li class="step step-primary">Create Account</li>

              <li class="step step-primary">Set Goals</li>

              <li class="step">Complete Lessons</li>

              <li class="step">Track Progress</li>
            </ul>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("date_changed", %{"start_date_str" => start_date_str, "end_date_str" => end_date_str}, socket) do
    {:noreply, socket |> assign(:startDateStr, start_date_str) |> assign(:endDateStr, end_date_str)}
  end
end
