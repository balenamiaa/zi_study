defmodule ZiStudyWeb.ActiveLearningLive.QuestionSet do
  use ZiStudyWeb, :live_view

  alias ZiStudyWeb.Live.ActiveLearning.QuestionHandlers

  def render(assigns) do
    ~H"""
    <Layouts.active_learning flash={@flash} current_scope={@current_scope}>
      <.svelte
        name="pages/ActiveLearningQuestionSet"
        socket={@socket}
        props={
          %{
            # Small metadata only
            questionSetMeta: @question_set_meta,
            # Initial questions for SSR (first 10)
            initialQuestions: @initial_questions,
            initialAnswers: @initial_answers,
            # Streaming state
            streamingState: @streaming_state,
            # User data
            currentUser: @current_user_dto,
            userQuestionSets: @user_question_sets
          }
        }
      />
    </Layouts.active_learning>
    """
  end

  def mount(params, _session, socket) do
    current_user = socket.assigns.current_scope.user
    question_set_id = String.to_integer(params["id"])

    # Load just metadata first
    question_set_meta =
      QuestionHandlers.get_question_set_metadata(question_set_id, current_user.id)

    # Get initial chunk for SSR (first 10 questions)
    {initial_chunk, streaming_state} =
      QuestionHandlers.get_initial_questions_chunk(
        question_set_id,
        current_user.id,
        # Initial chunk size for SSR
        10
      )

    {:ok,
     socket
     |> assign(:question_set_id, question_set_id)
     |> assign(:question_set_meta, question_set_meta)
     |> assign(:initial_questions, initial_chunk.questions)
     |> assign(:initial_answers, initial_chunk.answers)
     |> assign(:streaming_state, streaming_state)
     |> assign(:current_user_dto, QuestionHandlers.owner_to_dto(current_user))
     |> assign(:user_question_sets, nil)}
  end

  def handle_info(:stream_next_chunk, socket) do
    current_user = socket.assigns.current_scope.user
    question_set_id = socket.assigns.question_set_id
    streaming_state = socket.assigns.streaming_state

    if streaming_state.has_more do
      {questions_chunk, updated_streaming_state} =
        QuestionHandlers.get_questions_chunk(
          question_set_id,
          current_user.id,
          streaming_state.loaded_count,
          # Chunk size for streaming
          30
        )

      # Send chunk via event (not props!)
      {:noreply,
       socket
       |> assign(:streaming_state, updated_streaming_state)
       |> push_event("questions_chunk_received", %{
         questions: questions_chunk.questions,
         answers: questions_chunk.answers,
         streaming_state: updated_streaming_state
       })
       |> maybe_schedule_next_chunk(updated_streaming_state)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("start_streaming", _params, socket) do
    streaming_state = socket.assigns.streaming_state

    if streaming_state.has_more && !streaming_state.is_streaming do
      send(self(), :stream_next_chunk)

      updated_streaming_state = Map.put(streaming_state, :is_streaming, true)

      {:noreply, assign(socket, :streaming_state, updated_streaming_state)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("request_more_questions", _params, socket) do
    send(self(), :stream_next_chunk)
    {:noreply, socket}
  end

  def handle_event("answer_question", %{"question_id" => question_id, "answer" => answer}, socket) do
    current_user = socket.assigns.current_scope.user

    case QuestionHandlers.handle_answer_question(question_id, answer, current_user) do
      {:ok, answer_dto, event_data} ->
        {:noreply,
         socket
         |> push_event("answer_updated", %{
           answer: answer_dto,
           event_data: event_data
         })
         |> push_event("answer_submitted", event_data)}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("clear_answer", %{"question_id" => question_id}, socket) do
    current_user = socket.assigns.current_scope.user
    question_id_int = String.to_integer(question_id)

    case QuestionHandlers.handle_clear_answer(question_id, current_user) do
      {:ok, _event_data} ->
        {:noreply,
         socket
         |> push_event("answer_reset", %{question_id: question_id_int})}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event(
        "self_evaluate_answer",
        %{"question_id" => question_id, "is_correct" => is_correct},
        socket
      ) do
    current_user = socket.assigns.current_scope.user

    case QuestionHandlers.handle_self_evaluate_answer(question_id, is_correct, current_user) do
      {:ok, answer_dto} ->
        {:noreply,
         socket
         |> push_event("answer_updated", %{
           answer: answer_dto,
           event_data: %{question_id: question_id}
         })}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("update_question_set", %{"field" => field, "value" => value}, socket) do
    current_user = socket.assigns.current_scope.user
    question_set_id = socket.assigns.question_set_id

    case QuestionHandlers.handle_update_question_set(question_set_id, field, value, current_user) do
      {:ok, _updated_set} ->
        # Update metadata via event
        field_atom = String.to_atom(field)

        {:noreply,
         socket
         |> update(:question_set_meta, &Map.put(&1, field_atom, value))
         |> push_event("question_set_meta_updated", %{
           field: field,
           value: value
         })}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("clear_user_question_sets", _params, socket) do
    {:noreply, assign(socket, :user_question_sets, nil)}
  end

  def handle_event(
        "load_owned_question_sets_for_question",
        %{
          "question_id" => question_id,
          "page_number" => page_number,
          "search_query" => search_query
        },
        socket
      ) do
    current_user = socket.assigns.current_scope.user

    question_sets_data =
      QuestionHandlers.handle_load_owned_question_sets_for_question(
        question_id,
        page_number,
        search_query,
        current_user
      )

    {:noreply, assign(socket, :user_question_sets, question_sets_data)}
  end

  def handle_event(
        "modify_question_sets",
        %{"question_id" => question_id, "question_set_modifications" => modifications},
        socket
      ) do
    current_user = socket.assigns.current_scope.user

    case QuestionHandlers.handle_modify_question_sets(question_id, modifications, current_user) do
      {:ok, result} ->
        message =
          cond do
            result.added_to_sets > 0 and result.removed_from_sets > 0 ->
              "Added to #{result.added_to_sets} set(s), removed from #{result.removed_from_sets} set(s)"

            result.added_to_sets > 0 ->
              "Added to #{result.added_to_sets} set(s)"

            result.removed_from_sets > 0 ->
              "Removed from #{result.removed_from_sets} set(s)"

            true ->
              "No changes made"
          end

        {:noreply,
         socket
         |> put_flash(:info, message)
         |> push_event("question_sets_modified", %{
           total_modified: result.total_modified,
           modified_sets: result.modified_sets
         })}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("quick_create_question_set", %{"title" => title}, socket) do
    current_user = socket.assigns.current_scope.user

    case QuestionHandlers.handle_quick_create_question_set(title, current_user) do
      {:ok, _question_set} ->
        {:noreply,
         socket
         |> put_flash(:info, "Question set created successfully")
         |> push_event("set_created", %{})}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("load_all_tags", %{"search_query" => search_query}, socket) do
    tags = QuestionHandlers.handle_load_tags(search_query)

    {:noreply,
     socket
     |> push_event("tags_loaded", %{tags: tags})}
  end

  def handle_event("create_tag", %{"name" => name}, socket) do
    case QuestionHandlers.handle_create_tag(name) do
      {:ok, tag} ->
        {:noreply,
         socket
         |> push_event("tag_created", %{tag: tag})}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("add_tags_to_question_set", %{"question_set_id" => question_set_id, "tag_ids" => tag_ids}, socket) do
    current_user = socket.assigns.current_scope.user

    case QuestionHandlers.handle_add_tags_to_question_set(question_set_id, tag_ids, current_user) do
      {:ok, updated_set} ->
        # Update the question set meta with new tags
        updated_meta = Map.put(socket.assigns.question_set_meta, :tags, Enum.map(updated_set.tags, &QuestionHandlers.get_tag_dto/1))

        {:noreply,
         socket
         |> assign(:question_set_meta, updated_meta)
         |> push_event("question_set_meta_updated", %{
           field: "tags",
           value: updated_meta.tags
         })}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("remove_tags_from_question_set", %{"question_set_id" => question_set_id, "tag_ids" => tag_ids}, socket) do
    current_user = socket.assigns.current_scope.user

    case QuestionHandlers.handle_remove_tags_from_question_set(question_set_id, tag_ids, current_user) do
      {:ok, updated_set} ->
        # Update the question set meta with new tags
        updated_meta = Map.put(socket.assigns.question_set_meta, :tags, Enum.map(updated_set.tags, &QuestionHandlers.get_tag_dto/1))

        {:noreply,
         socket
         |> assign(:question_set_meta, updated_meta)
         |> push_event("question_set_meta_updated", %{
           field: "tags",
           value: updated_meta.tags
         })}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("clear_tags", _params, socket) do
    # Just a cleanup event from the modal, no action needed
    {:noreply, socket}
  end

  defp maybe_schedule_next_chunk(socket, streaming_state) do
    if streaming_state.has_more do
      Process.send_after(self(), :stream_next_chunk, 100)
    end

    socket
  end
end
