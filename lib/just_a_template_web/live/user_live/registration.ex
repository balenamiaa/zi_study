defmodule JustATemplateWeb.UserLive.Registration do
  use JustATemplateWeb, :live_view

  alias JustATemplate.Accounts
  alias JustATemplate.Accounts.User

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <.header class="text-center">
          Register for an account
          <:subtitle>
            Already registered?
            <.link navigate={~p"/users/log-in"} class="font-semibold text-brand hover:underline">
              Log in
            </.link>
            to your account now.
          </:subtitle>
        </.header>

        <.form for={@form} id="registration_form" phx-submit="save" phx-change="validate">
          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
            phx-mounted={JS.focus()}
          />

          <div class="mb-4">
            <label class="fieldset-label mb-2">Profile Picture</label>
            <.svelte
              name="AvatarUpload"
              props={
                %{
                  currentUrl: @current_avatar_url,
                  size: "lg"
                }
              }
              socket={@socket}
            >
              <.live_file_input
                upload={@uploads.profile_picture}
                class="hidden"
                id="avatar-file-input"
              />
            </.svelte>
          </div>

          <.button variant="primary" phx-disable-with="Creating account..." class="w-full">
            Create an account
          </.button>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: JustATemplateWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_email(%User{})

    socket =
      socket
      |> assign_form(changeset)
      |> assign(:current_avatar_url, nil)
      |> assign(:uploaded_files, [])
      |> allow_upload(:profile_picture,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 1,
        # 5MB
        max_file_size: 5_242_880,
        auto_upload: true
      )

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    profile_picture_filename = handle_profile_picture_uploads(socket)
    user_params = Map.put(user_params, "profile_picture", profile_picture_filename)

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_email(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp handle_profile_picture_uploads(socket) do
    case consume_uploaded_entries(socket, :profile_picture, fn %{path: path}, entry ->
           ext = Path.extname(entry.client_name)
           filename = "#{Ecto.UUID.generate()}#{ext}"
           dest = Path.join(Accounts.profile_picture_path(), filename)
           File.cp!(path, dest)
           {:ok, filename}
         end) do
      [] ->
        case socket.assigns[:current_avatar_url] do
          nil -> nil
          url -> extract_filename_from_url(url)
        end

      [filename] ->
        filename
    end
  end

  defp extract_filename_from_url(url) do
    case String.split(url, "/") do
      [_ | _] = parts -> List.last(parts)
      _ -> nil
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
