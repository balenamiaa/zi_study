defmodule ZiStudy.Fixtures do
  @moduledoc """
  This module defines test fixtures for creating valid data for tests.
  """

  alias ZiStudy.Accounts
  alias ZiStudy.Questions
  alias ZiStudy.QuestionsOps.Processed

  # Helper function to convert atom keys to string keys
  defp stringify_keys(map) when is_map(map) do
    for {key, value} <- map, into: %{} do
      case key do
        key when is_atom(key) -> {to_string(key), value}
        key when is_binary(key) -> {key, value}
      end
    end
  end

  @doc """
  Generate a unique user email.
  """
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  @doc """
  Generate a unique user username.
  """
  def unique_user_username, do: "user#{System.unique_integer()}"

  @doc """
  Generate user attributes for testing.
  """
  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      username: unique_user_username(),
      password: "hello world!"
    })
  end

  @doc """
  Create a user for testing.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    user
  end

  @doc """
  Generate question set attributes.
  """
  def valid_question_set_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      "title" => "Test Question Set #{System.unique_integer()}",
      "description" => "A test question set for automated testing",
      "is_private" => false
    })
  end

  @doc """
  Create a question set for testing.
  """
  def question_set_fixture(user \\ nil, attrs \\ %{}) do
    # Normalize attrs keys to strings for consistency with valid_question_set_attributes
    normalized_attrs =
      for {key, value} <- attrs, into: %{} do
        case key do
          key when is_atom(key) -> {to_string(key), value}
          key when is_binary(key) -> {key, value}
        end
      end

    case user do
      nil ->
        {:ok, question_set} =
          normalized_attrs
          |> valid_question_set_attributes()
          |> Questions.create_question_set_ownerless()

        question_set

      user ->
        {:ok, question_set} =
          normalized_attrs
          |> valid_question_set_attributes()
          |> then(&Questions.create_question_set(user, &1))

        question_set
    end
  end

  @doc """
  Generate tag attributes.
  """
  def valid_tag_attributes(attrs \\ %{}) do
    Map.merge(%{
      "name" => "test-tag-#{System.unique_integer()}"
    }, stringify_keys(attrs))
  end

  @doc """
  Create a tag for testing.
  """
  def tag_fixture(attrs \\ %{}) do
    {:ok, tag} =
      attrs
      |> valid_tag_attributes()
      |> Questions.create_tag()

    tag
  end

  @doc """
  Generate MCQ single question data in processed format.
  """
  def mcq_single_question_data do
    %{
      "question_text" => "What is 2 + 2?",
      "options" => ["3", "4", "5", "6"],
      "correct_index" => 1,
      "explanation" => "2 + 2 = 4",
      "difficulty" => "easy",
      "question_type" => "mcq_single"
    }
  end

  @doc """
  Generate MCQ single question data in import format.
  """
  def mcq_single_import_data do
    %{
      "temp_id" => "mcq1",
      "question_text" => "What is 2 + 2?",
      "options" => [
        %{"temp_id" => "opt1", "text" => "3"},
        %{"temp_id" => "opt2", "text" => "4"},
        %{"temp_id" => "opt3", "text" => "5"},
        %{"temp_id" => "opt4", "text" => "6"}
      ],
      "correct_option_temp_id" => "opt2",
      "explanation" => "2 + 2 = 4",
      "difficulty" => "easy",
      "question_type" => "mcq_single"
    }
  end

  @doc """
  Generate MCQ multiple question data in processed format.
  """
  def mcq_multi_question_data do
    %{
      "question_text" => "Which of the following are prime numbers?",
      "options" => ["2", "3", "4", "5"],
      "correct_indices" => [0, 1, 3],
      "explanation" => "2, 3, and 5 are prime numbers",
      "difficulty" => "medium",
      "question_type" => "mcq_multi"
    }
  end

  @doc """
  Generate MCQ multiple question data in import format.
  """
  def mcq_multi_import_data do
    %{
      "temp_id" => "mcq_multi1",
      "question_text" => "Which of the following are prime numbers?",
      "options" => [
        %{"temp_id" => "opt1", "text" => "2"},
        %{"temp_id" => "opt2", "text" => "3"},
        %{"temp_id" => "opt3", "text" => "4"},
        %{"temp_id" => "opt4", "text" => "5"}
      ],
      "correct_option_temp_ids" => ["opt1", "opt2", "opt4"],
      "explanation" => "2, 3, and 5 are prime numbers",
      "difficulty" => "medium",
      "question_type" => "mcq_multi"
    }
  end

  @doc """
  Generate true/false question data in processed format.
  """
  def true_false_question_data do
    %{
      "question_text" => "The Earth is round.",
      "is_correct_true" => true,
      "explanation" => "The Earth is approximately spherical",
      "difficulty" => "easy",
      "question_type" => "true_false"
    }
  end

  @doc """
  Generate true/false question data in import format.
  """
  def true_false_import_data do
    %{
      "temp_id" => "tf1",
      "question_text" => "The Earth is round.",
      "is_correct_true" => true,
      "explanation" => "The Earth is approximately spherical",
      "difficulty" => "easy",
      "question_type" => "true_false"
    }
  end

  @doc """
  Generate written question data in processed format.
  """
  def written_question_data do
    %{
      "question_text" => "Explain the concept of gravity.",
      "correct_answer" => "Gravity is a fundamental force that attracts objects with mass",
      "explanation" => "Gravity is described by Einstein's general relativity",
      "difficulty" => "hard",
      "question_type" => "written"
    }
  end

  @doc """
  Generate written question data in import format.
  """
  def written_import_data do
    %{
      "temp_id" => "written1",
      "question_text" => "Explain the concept of gravity.",
      "correct_answer_text" => "Gravity is a fundamental force that attracts objects with mass",
      "explanation" => "Gravity is described by Einstein's general relativity",
      "difficulty" => "hard",
      "question_type" => "written"
    }
  end

  @doc """
  Generate cloze question data in processed format.
  """
  def cloze_question_data do
    %{
      "question_text" => "The capital of France is _____ and it is located in _____.",
      "answers" => ["Paris", "Europe"],
      "explanation" => "Paris is the capital and largest city of France",
      "difficulty" => "easy",
      "question_type" => "cloze"
    }
  end

  @doc """
  Generate cloze question data in import format.
  """
  def cloze_import_data do
    %{
      "temp_id" => "cloze1",
      "question_text" => "The capital of France is _____ and it is located in _____.",
      "answers" => ["Paris", "Europe"],
      "explanation" => "Paris is the capital and largest city of France",
      "difficulty" => "easy",
      "question_type" => "cloze"
    }
  end

  @doc """
  Generate EMQ question data in processed format.
  """
  def emq_question_data do
    %{
      "instructions" => "Match each planet with its position from the Sun",
      "premises" => ["First planet", "Second planet", "Third planet"],
      "options" => ["Mercury", "Venus", "Earth", "Mars"],
      "matches" => [[0, 0], [1, 1], [2, 2]],
      "explanation" => "Mercury, Venus, and Earth are the first three planets",
      "difficulty" => "medium",
      "question_type" => "emq"
    }
  end

  @doc """
  Generate EMQ question data in import format.
  """
  def emq_import_data do
    %{
      "temp_id" => "emq1",
      "instructions" => "Match each planet with its position from the Sun",
      "premises" => [
        %{"temp_id" => "p1", "text" => "First planet"},
        %{"temp_id" => "p2", "text" => "Second planet"},
        %{"temp_id" => "p3", "text" => "Third planet"}
      ],
      "options" => [
        %{"temp_id" => "o1", "text" => "Mercury"},
        %{"temp_id" => "o2", "text" => "Venus"},
        %{"temp_id" => "o3", "text" => "Earth"},
        %{"temp_id" => "o4", "text" => "Mars"}
      ],
      "matches" => [["p1", "o1"], ["p2", "o2"], ["p3", "o3"]],
      "explanation" => "Mercury, Venus, and Earth are the first three planets",
      "difficulty" => "medium",
      "question_type" => "emq"
    }
  end

  @doc """
  Create a question for testing.
  """
  def question_fixture(type \\ :mcq_single, attrs \\ %{}) do
    base_data =
      case type do
        :mcq_single -> mcq_single_question_data()
        :mcq_multi -> mcq_multi_question_data()
        :true_false -> true_false_question_data()
        :written -> written_question_data()
        :cloze -> cloze_question_data()
        :emq -> emq_question_data()
      end

    data = Map.merge(base_data, attrs)
    processed_content = Processed.Question.from_map(data)

    {:ok, question} = Questions.create_question(processed_content)
    question
  end

  @doc """
  Generate answer attributes.
  """
  def valid_answer_attributes(user, question, attrs \\ %{}) do
    base_data =
      case question.type do
        "mcq_single" -> %{"selected_index" => 1}
        "mcq_multi" -> %{"selected_indices" => [0, 1]}
        "true_false" -> %{"selected" => true}
        "written" -> %{"answer_text" => "Sample written answer"}
        "cloze" -> %{"answers" => ["Paris", "Europe"]}
        "emq" -> %{"matches" => [[0, 0], [1, 1]]}
        _ -> %{"generic_answer" => "test"}
      end

    Enum.into(attrs, %{
      user_id: user.id,
      question_id: question.id,
      data: Map.merge(base_data, Map.get(attrs, :data, %{})),
      # unevaluated by default
      is_correct: 2
    })
  end

  @doc """
  Create an answer for testing.
  """
  def answer_fixture(user, question, attrs \\ %{}) do
    {:ok, answer} =
      user
      |> valid_answer_attributes(question, attrs)
      |> Questions.create_answer()

    answer
  end

  @doc """
  Create a correct answer for testing.
  """
  def correct_answer_fixture(user, question, attrs \\ %{}) do
    correct_data =
      case question.type do
        "mcq_single" ->
          correct_index = question.data["correct_index"]
          %{"selected_index" => correct_index}

        "mcq_multi" ->
          correct_indices = question.data["correct_indices"]
          %{"selected_indices" => correct_indices}

        "true_false" ->
          correct = question.data["is_correct_true"]
          %{"selected" => correct}

        "cloze" ->
          correct_answers = question.data["answers"]
          %{"answers" => correct_answers}

        "emq" ->
          correct_matches = question.data["matches"]
          %{"matches" => correct_matches}

        _ ->
          %{}
      end

    attrs_with_correct_data = Map.put(attrs, :data, correct_data)
    answer_fixture(user, question, attrs_with_correct_data)
  end

  @doc """
  Create an incorrect answer for testing.
  """
  def incorrect_answer_fixture(user, question, attrs \\ %{}) do
    incorrect_data =
      case question.type do
        "mcq_single" ->
          correct_index = question.data["correct_index"]
          wrong_index = if correct_index == 0, do: 1, else: 0
          %{"selected_index" => wrong_index}

        "mcq_multi" ->
          # Assuming this is wrong
          %{"selected_indices" => [0]}

        "true_false" ->
          correct = question.data["is_correct_true"]
          %{"selected" => not correct}

        "cloze" ->
          %{"answers" => ["Wrong", "Answer"]}

        "emq" ->
          # Swapped matches
          %{"matches" => [[0, 1], [1, 0]]}

        _ ->
          %{"wrong" => "answer"}
      end

    attrs_with_incorrect_data = Map.put(attrs, :data, incorrect_data)
    answer_fixture(user, question, attrs_with_incorrect_data)
  end
end
