defmodule JustATemplateWeb.UserLive.Registration do
  use JustATemplateWeb, :live_view

  alias JustATemplate.Accounts
  alias JustATemplate.Accounts.User
  alias Ecto.UUID

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
          <.svelte
            name="AvatarUpload"
            class="mb-4 mx-auto w-fit"
            props={
              %{
                image_preview_url: @image_preview_url,
                size: "lg"
              }
            }
            socket={@socket}
          />

          <.input
            field={@form[:email]}
            type="email"
            label="Email"
            autocomplete="username"
            required
            phx-mounted={JS.focus()}
          />

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
      |> assign(:image_preview_url, nil)
      |> assign(:uploaded_image_file_name, nil)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    %{assigns: %{uploaded_image_file_name: profile_picture_filename}} = socket

    IO.inspect(profile_picture_filename, label: "Profile picture filename")
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

  def handle_event("upload_from_url", %{"url" => image_url}, socket) do
    case HTTPoison.get(image_url, [], timeout: 15000, recv_timeout: 15000) do
      {:ok, %HTTPoison.Response{status_code: 200, headers: headers, body: body}} ->
        # TODO: Do not rely on content-type header. Download the URL and use a library to parse the image

        content_type = List.keyfind(headers, "content-type", 0, {"content-type", ""}) |> elem(1)

        if String.starts_with?(content_type, "image/") do
          original_file_name = extract_filename_from_url_or_headers(image_url, headers)
          {final_path, preview_url, saved_file_name} = final_upload_details(original_file_name)

          case File.write(final_path, body) do
            :ok ->
              new_socket =
                socket
                |> assign(:image_preview_url, preview_url)
                |> assign(:uploaded_image_file_name, saved_file_name)
                |> clear_upload_assigns()

              {:noreply, push_event(new_socket, "upload_success", %{preview_url: preview_url})}

            {:error, reason} ->
              IO.warn("Failed to write fetched image to file: #{reason}",
                label: "Upload From URL Error"
              )

              {:noreply,
               push_event(socket, "upload_error", %{message: "Failed to save downloaded image."})}
          end
        else
          IO.warn("Invalid content type for URL '#{image_url}': #{content_type}",
            label: "Upload From URL Error"
          )

          {:noreply,
           push_event(socket, "upload_error", %{
             message: "URL does not point to a valid image (e.g. JPG, PNG)."
           })}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        IO.warn(
          "Failed to fetch image from URL '#{image_url}', status: #{status_code}, body: #{inspect(body)}",
          label: "Upload From URL Error"
        )

        {:noreply,
         push_event(socket, "upload_error", %{
           message: "Failed to fetch image. Server responded with status #{status_code}."
         })}

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.warn("Error fetching image from URL '#{image_url}': #{reason}",
          label: "Upload From URL Error"
        )

        message =
          case reason do
            :timeout -> "Connection to the image URL timed out."
            :nxdomain -> "The image URL host does not exist."
            :econnrefused -> "Connection to the image URL was refused."
            _ -> "Could not connect to the image URL."
          end

        {:noreply, push_event(socket, "upload_error", %{message: message})}
    end
  end

  def handle_event(
        "upload_file_chunked",
        %{"state" => "start", "file_name" => file_name, "file_size" => file_size},
        socket
      ) do
    temp_path = temp_upload_path(socket, file_name)
    File.rm(temp_path)

    case File.open(temp_path, [:write, :binary]) do
      {:ok, io_device} ->
        new_socket =
          socket
          |> assign(:upload_temp_path, temp_path)
          |> assign(:upload_file_name, file_name)
          |> assign(:upload_file_size, file_size)
          |> assign(:upload_received_size, 0)
          |> assign(:upload_io_device, io_device)

        {:noreply, new_socket}

      {:error, reason} ->
        IO.inspect("Failed to open temp file for upload: #{reason}", label: "Upload Start Error")
        {:noreply, socket}
    end
  end

  def handle_event(
        "upload_file_chunked",
        %{"state" => "chunk", "base64_chunk_data" => base64_chunk_data},
        socket
      ) do
    %{
      assigns: %{
        upload_io_device: io_device,
        upload_received_size: received_size,
        upload_temp_path: temp_path
      }
    } = socket

    if !io_device do
      IO.warn("Upload IO device not found in socket assigns for chunk processing.",
        label: "Upload Chunk Error"
      )

      new_socket = clear_upload_assigns(socket)
      File.rm(temp_path)
      {:noreply, new_socket}
    else
      case Base.decode64(base64_chunk_data, padding: false) do
        {:ok, chunk_data} ->
          try do
            :ok = IO.binwrite(io_device, chunk_data)

            new_received_size = received_size + byte_size(chunk_data)
            new_socket = assign(socket, :upload_received_size, new_received_size)
            {:noreply, new_socket}
          rescue
            e ->
              IO.warn("Error writing chunk data: #{inspect(e)}", label: "Upload Chunk Error")
              File.close(io_device)
              File.rm(temp_path)
              new_socket = clear_upload_assigns(socket)

              {:noreply,
               push_event(new_socket, "upload_error", %{message: "Error processing image data."})}
          end

        :error ->
          IO.warn("Error decoding base64 chunk data", label: "Upload Chunk Decode Error")
          File.close(io_device)
          File.rm(temp_path)
          new_socket = clear_upload_assigns(socket)

          {:noreply,
           push_event(new_socket, "upload_error", %{message: "Error processing image data."})}
      end
    end
  end

  def handle_event("upload_file_chunked", %{"state" => "end"}, socket) do
    %{
      assigns: %{
        upload_temp_path: temp_path,
        upload_file_name: original_file_name,
        upload_file_size: expected_size,
        upload_received_size: received_size,
        upload_io_device: io_device
      }
    } = socket

    if !io_device do
      IO.warn("Upload IO device not found in socket assigns for 'end' state.",
        label: "Upload End Error"
      )

      File.rm(temp_path)
      new_socket = clear_upload_assigns(socket)
      {:noreply, new_socket}
    else
      :ok = File.close(io_device)

      if !temp_path || received_size != expected_size do
        IO.warn(
          "Upload ended but file size mismatch or temp path missing. Expected: #{expected_size}, Got: #{received_size}",
          label: "Upload End Error"
        )

        File.rm(temp_path)
        new_socket = clear_upload_assigns(socket)

        {:noreply,
         push_event(new_socket, "upload_error", %{
           message: "Image upload failed: incomplete data."
         })}
      else
        {final_path, preview_url, saved_file_name} = final_upload_details(original_file_name)

        case File.rename(temp_path, final_path) do
          :ok ->
            new_socket =
              socket
              |> assign(:image_preview_url, preview_url)
              |> assign(:uploaded_image_file_name, saved_file_name)
              |> clear_upload_assigns()

            {:noreply, push_event(new_socket, "upload_success", %{preview_url: preview_url})}

          {:error, reason} ->
            IO.warn("Failed to rename temp file: #{inspect(reason)}",
              label: "Upload End Rename Error"
            )

            File.rm(temp_path)
            new_socket = clear_upload_assigns(socket)

            {:noreply,
             push_event(new_socket, "upload_error", %{message: "Failed to save uploaded image."})}
        end
      end
    end
  end

  def handle_event(
        "upload_file_chunked",
        %{"state" => "error", "file_name" => file_name, "error_message" => error_message},
        socket
      ) do
    IO.warn("Received client-side upload error for #{file_name}: #{error_message}",
      label: "Upload Client Error"
    )

    if io_device = socket.assigns[:upload_io_device] do
      File.close(io_device)
    end

    if temp_path = socket.assigns[:upload_temp_path] do
      File.rm(temp_path)
    end

    new_socket = clear_upload_assigns(socket)
    {:noreply, new_socket}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end

  defp temp_upload_base_dir do
    Path.join([Application.app_dir(:just_a_template, "priv"), "static", "uploads", "tmp"])
  end

  defp temp_upload_path(socket, file_name) do
    base_dir = temp_upload_base_dir()
    File.mkdir_p!(base_dir)
    sane_file_name = file_name |> String.replace(~r/[^\w.-]/, "_")
    Path.join(base_dir, "#{socket.id}-#{sane_file_name}")
  end

  defp final_upload_details(original_file_name) do
    sane_file_name =
      original_file_name
      |> String.replace(~r/[^\w.-]/, "_")
      |> (&"#{UUID.generate()}-#{&1}").()

    base_dir = Accounts.profile_picture_path_base()
    File.mkdir_p!(base_dir)
    final_path = Path.join(base_dir, sane_file_name)
    preview_url = Accounts.profile_picture_serving_path(sane_file_name)
    {final_path, preview_url, sane_file_name}
  end

  defp clear_upload_assigns(socket) do
    socket
    |> assign(:upload_temp_path, nil)
    |> assign(:upload_file_name, nil)
    |> assign(:upload_file_size, nil)
    |> assign(:upload_received_size, nil)
    |> assign(:upload_io_device, nil)
  end

  defp extract_filename_from_url_or_headers(image_url, headers) do
    content_disposition =
      List.keyfind(headers, "Content-Disposition", 0, {"Content-Disposition", ""}) |> elem(1)

    filename_from_header =
      if String.contains?(content_disposition, "filename=") do
        content_disposition
        |> String.split("filename=")
        |> List.last()
        # Trim leading/trailing quotes
        |> String.trim("\"")
        |> String.trim()
      else
        nil
      end

    cond do
      filename_from_header && String.length(filename_from_header) > 0 ->
        filename_from_header

      true ->
        # Fallback to extracting from URL path
        # Default with a common extension
        default_name = "downloaded_image.jpg"

        try do
          uri = URI.parse(image_url)
          path_basename = Path.basename(uri.path || "")
          if String.length(path_basename) > 0, do: path_basename, else: default_name
        rescue
          # Default if URL parsing fails or path is empty
          _ -> default_name
        end
    end
  end
end
