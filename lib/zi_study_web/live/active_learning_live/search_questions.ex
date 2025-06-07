defmodule ZiStudyWeb.ActiveLearningLive.SearchQuestions do
  use ZiStudyWeb, :live_view

  alias ZiStudy.Questions
  alias ZiStudyWeb.Live.QuestionHandlers

  def render(assigns) do
    ~H"""
    <Layouts.active_learning flash={@flash} current_scope={@current_scope}>
      <.svelte
        name="pages/ActiveLearningSearchQuestions"
        socket={@socket}
        props={
          %{
            searchResults: @search_results,
            searchConfig: @search_config,
            isSearching: @is_searching,
            cursor: @cursor,
            hasMore: @has_more,
            selectedQuestionIds: MapSet.to_list(@selected_question_ids),
            bulkSelectMode: @bulk_select_mode,
            userQuestionSets: @user_question_sets,
            currentUser: @current_user_dto
          }
        }
      />
    </Layouts.active_learning>
    """
  end

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_scope.user

    default_config = %{
      search_scope: [:all],
      case_sensitive: false,
      sort_by: :relevance,
      question_types: [],
      difficulties: []
    }

    {:ok,
     socket
     |> assign(:current_user_dto, QuestionHandlers.owner_to_dto(current_user))
     |> assign(:search_results, [])
     |> assign(:search_config, default_config)
     |> assign(:is_searching, false)
     |> assign(:cursor, nil)
     |> assign(:has_more, false)
     |> assign(:selected_question_ids, MapSet.new())
     |> assign(:bulk_select_mode, false)
     |> assign(:user_question_sets, nil)}
  end

  def handle_event("search", %{"query" => query, "config" => config}, socket) do
    if String.trim(query) == "" do
      {:noreply,
       socket
       |> assign(:search_results, [])
       |> assign(:cursor, nil)
       |> assign(:has_more, false)}
    else
      search_config = parse_search_config(config)

      {:noreply,
       socket
       |> assign(:search_config, search_config)
       |> assign(:is_searching, true)
       |> perform_search(query, nil)}
    end
  end

  def handle_event("load_more", %{"query" => query}, socket) do
    if socket.assigns.cursor && socket.assigns.has_more do
      {:noreply,
       socket
       |> assign(:is_searching, true)
       |> perform_search(query, socket.assigns.cursor)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("toggle_bulk_select", _, socket) do
    bulk_select_mode = !socket.assigns.bulk_select_mode

    socket =
      if bulk_select_mode do
        socket
      else
        assign(socket, :selected_question_ids, MapSet.new())
      end

    {:noreply, assign(socket, :bulk_select_mode, bulk_select_mode)}
  end

  def handle_event("toggle_question_selection", %{"question_id" => question_id}, socket) do
    question_id_int = String.to_integer(question_id)
    selected_ids = socket.assigns.selected_question_ids

    new_selected_ids =
      if MapSet.member?(selected_ids, question_id_int) do
        MapSet.delete(selected_ids, question_id_int)
      else
        MapSet.put(selected_ids, question_id_int)
      end

    {:noreply, assign(socket, :selected_question_ids, new_selected_ids)}
  end

  def handle_event("select_all", _, socket) do
    all_ids =
      socket.assigns.search_results
      |> Enum.map(& &1.question.id)
      |> MapSet.new()

    {:noreply, assign(socket, :selected_question_ids, all_ids)}
  end

  def handle_event("clear_selection", _, socket) do
    {:noreply, assign(socket, :selected_question_ids, MapSet.new())}
  end

  def handle_event("bulk_add_to_sets", _, socket) do
    selected_ids = MapSet.to_list(socket.assigns.selected_question_ids)

    if length(selected_ids) > 0 do
      {:noreply, push_event(socket, "open_bulk_add_modal", %{question_ids: selected_ids})}
    else
      {:noreply, socket}
    end
  end

  def handle_event("answer_question", %{"question_id" => question_id, "answer" => answer}, socket) do
    current_user = socket.assigns.current_scope.user

    case QuestionHandlers.handle_answer_question(question_id, answer, current_user) do
      {:ok, answer_dto, event_data} ->
        {:noreply,
         socket
         |> update_search_result_answer(question_id, answer_dto)
         |> push_event("answer_submitted", event_data)}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}

      {:error, message, event_data} ->
        {:noreply,
         socket
         |> put_flash(:error, message)
         |> push_event("answer_submitted", event_data)}
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
        {:noreply, socket |> update_search_result_answer(question_id, answer_dto)}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("clear_answer", %{"question_id" => question_id}, socket) do
    current_user = socket.assigns.current_scope.user

    case QuestionHandlers.handle_clear_answer(question_id, current_user) do
      {:ok, event_data} ->
        {:noreply,
         socket
         |> clear_search_result_answer(question_id)
         |> push_event("answer_reset", event_data)}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("clear_user_question_sets", _params, socket) do
    {:noreply, assign(socket, :user_question_sets, nil)}
  end

  def handle_event("load_owned_question_sets_for_question", params, socket) do
    current_user = socket.assigns.current_scope.user

    question_sets_data =
      QuestionHandlers.handle_load_owned_question_sets_for_question(
        params["question_id"],
        params["page_number"],
        params["search_query"],
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
         |> push_event("set_created", %{})
         |> assign(:user_question_sets, nil)}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event(
        "load_accessible_question_sets",
        %{"page_number" => page_number, "search_query" => search_query},
        socket
      ) do
    current_user = socket.assigns.current_scope.user

    {question_sets, total_count} =
      Questions.get_user_accessible_question_sets(
        current_user.id,
        search_query,
        page_number,
        20
      )

    total_pages = div(total_count + 20 - 1, 20)

    items =
      Enum.map(
        question_sets,
        &QuestionHandlers.question_set_to_accessible_dto(&1, current_user.id)
      )

    accessible_sets_data = %{
      "page_size" => 20,
      "page_number" => page_number,
      "total_pages" => total_pages,
      "total_items" => total_count,
      "items" => items
    }

    {:noreply, push_event(socket, "accessible_sets_loaded", accessible_sets_data)}
  end

  def handle_event("clear_accessible_question_sets", _params, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "bulk_add_questions_to_sets",
        %{"question_ids" => question_ids, "question_set_ids" => question_set_ids},
        socket
      ) do
    current_user = socket.assigns.current_scope.user
    question_id_ints = Enum.map(question_ids, &String.to_integer/1)
    question_set_id_ints = Enum.map(question_set_ids, &String.to_integer/1)

    results =
      Enum.map(question_set_id_ints, fn set_id ->
        Questions.bulk_add_questions_to_set(current_user.id, question_id_ints, set_id)
      end)

    successful_sets = Enum.count(results, &match?({:ok, _}, &1))
    failed_sets = Enum.count(results, &match?({:error, _}, &1))

    message =
      cond do
        failed_sets == 0 ->
          "Successfully added #{length(question_ids)} question(s) to #{successful_sets} set(s)"

        successful_sets > 0 ->
          "Added to #{successful_sets} set(s), failed for #{failed_sets} set(s)"

        true ->
          "Failed to add questions to sets"
      end

    flash_type = if failed_sets == 0, do: :info, else: :warning

    {:noreply,
     socket
     |> put_flash(flash_type, message)
     |> push_event("questions_added_to_sets", %{count: successful_sets})}
  end

  defp perform_search(socket, query, cursor) do
    current_user = socket.assigns.current_scope.user
    config = socket.assigns.search_config

    opts = [
      cursor: cursor,
      limit: 20,
      search_scope: config.search_scope,
      case_sensitive: config.case_sensitive,
      sort_by: config.sort_by,
      question_types: config.question_types,
      difficulties: config.difficulties
    ]

    case Questions.search_questions_advanced(query, opts) do
      {results, next_cursor} ->
        # Get user answers for all questions
        questions = Enum.map(results, & &1.question)
        user_answers = Questions.get_user_answers_for_questions(current_user.id, questions)

        IO.inspect(questions)

        # Create answer lookup map
        answer_map =
          user_answers
          |> Enum.map(&{&1.question_id, QuestionHandlers.answer_to_dto(&1)})
          |> Enum.into(%{})

        # Convert to DTOs with answers
        search_result_dtos =
          results
          |> Enum.map(fn result ->
            %{
              question: QuestionHandlers.get_question_dto(result.question),
              answer: Map.get(answer_map, result.question.id),
              snippet: result.snippet,
              highlights: result.highlights,
              rank: result.rank
            }
          end)

        new_results =
          if cursor do
            socket.assigns.search_results ++ search_result_dtos
          else
            search_result_dtos
          end

        socket
        |> assign(:search_results, new_results)
        |> assign(:cursor, next_cursor)
        |> assign(:has_more, next_cursor != nil)
        |> assign(:is_searching, false)
    end
  rescue
    e ->
      socket
      |> put_flash(:error, "Search failed: #{inspect(e)}")
      |> assign(:is_searching, false)
  end

  # Private functions
  defp update_search_result_answer(socket, question_id, answer_dto) do
    question_id_int = String.to_integer(question_id)

    updated_results =
      socket.assigns.search_results
      |> Enum.map(fn result ->
        if result.question.id == question_id_int do
          %{result | answer: answer_dto}
        else
          result
        end
      end)

    assign(socket, :search_results, updated_results)
  end

  defp clear_search_result_answer(socket, question_id) do
    question_id_int = String.to_integer(question_id)

    updated_results =
      socket.assigns.search_results
      |> Enum.map(fn result ->
        if result.question.id == question_id_int do
          %{result | answer: nil}
        else
          result
        end
      end)

    assign(socket, :search_results, updated_results)
  end

  defp parse_search_config(config) do
    %{
      search_scope: parse_search_scope(config["search_scope"]),
      case_sensitive: config["case_sensitive"] || false,
      sort_by: String.to_atom(config["sort_by"] || "relevance"),
      question_types: config["question_types"] || [],
      difficulties: config["difficulties"] || []
    }
  end

  defp parse_search_scope(nil), do: [:all]

  defp parse_search_scope(scope) when is_list(scope) do
    Enum.map(scope, &String.to_atom/1)
  end

  defp parse_search_scope(_), do: [:all]
end
