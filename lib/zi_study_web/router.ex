defmodule ZiStudyWeb.Router do
  use ZiStudyWeb, :router

  import ZiStudyWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ZiStudyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ZiStudyWeb do
    pipe_through :browser

    delete "/users/log-out", UserSessionController, :delete
    post "/users/log-in", UserSessionController, :create
  end

  scope "/", ZiStudyWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{ZiStudyWeb.UserAuth, :mount_current_scope}] do
      live "/", HomeLive, :index
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", ZiStudyWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:zi_study, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ZiStudyWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ZiStudyWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ZiStudyWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/active-learning", ZiStudyWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :active_learning,
      on_mount: [{ZiStudyWeb.UserAuth, :require_authenticated}] do
      live "/", ActiveLearningLive.Index
      live "/question_sets", ActiveLearningLive.QuestionSets
      live "/question_set/:id", ActiveLearningLive.QuestionSet
      live "/search_questions", ActiveLearningLive.SearchQuestions
    end
  end
end
