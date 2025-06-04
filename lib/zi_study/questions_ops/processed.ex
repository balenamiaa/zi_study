defmodule ZiStudy.QuestionsOps.Processed do
  @moduledoc """
  Defines structs for processed question content that is stored in the database.

  This module contains the standardized question format used after import processing
  and before database insertion. All question types have common fields like question_text,
  difficulty, explanation, and retention_aid, with type-specific fields for each question format.
  """

  defmodule Answer do
    @moduledoc """
    Contains all processed answer type structs and conversion functions.

    Each answer type struct represents the standardized format of a user's answer
    that will be stored in the database and validated against the question data.
    """

    defmodule McqSingleAnswer do
      @moduledoc """
      Answer for a Multiple Choice Question with a single correct answer.
      """
      @enforce_keys [:selected_index]
      defstruct [
        :selected_index,
        answer_type: "mcq_single"
      ]

      @type t :: %__MODULE__{
              selected_index: non_neg_integer,
              answer_type: String.t()
            }
    end

    defmodule McqMultiAnswer do
      @moduledoc """
      Answer for a Multiple Choice Question with multiple correct answers.
      """
      @enforce_keys [:selected_indices]
      defstruct [
        :selected_indices,
        answer_type: "mcq_multi"
      ]

      @type t :: %__MODULE__{
              selected_indices: [non_neg_integer],
              answer_type: String.t()
            }
    end

    defmodule WrittenAnswer do
      @moduledoc """
      Answer for an open-ended written response question.
      """
      @enforce_keys [:text]
      defstruct [
        :text,
        answer_type: "written"
      ]

      @type t :: %__MODULE__{
              text: String.t(),
              answer_type: String.t()
            }
    end

    defmodule TrueFalseAnswer do
      @moduledoc """
      Answer for a True/False question.
      """
      @enforce_keys [:selected]
      defstruct [
        :selected,
        answer_type: "true_false"
      ]

      @type t :: %__MODULE__{
              selected: boolean(),
              answer_type: String.t()
            }
    end

    defmodule ClozeAnswer do
      @moduledoc """
      Answer for a fill-in-the-blanks question.
      """
      @enforce_keys [:answers]
      defstruct [
        :answers,
        answer_type: "cloze"
      ]

      @type t :: %__MODULE__{
              answers: [String.t()],
              answer_type: String.t()
            }
    end

    defmodule EmqAnswer do
      @moduledoc """
      Answer for an Extended Matching Question.
      """
      @enforce_keys [:matches]
      defstruct [
        :matches,
        answer_type: "emq"
      ]

      @type t :: %__MODULE__{
              matches: [[non_neg_integer]],
              answer_type: String.t()
            }
    end

    @type t ::
            McqSingleAnswer.t()
            | McqMultiAnswer.t()
            | WrittenAnswer.t()
            | TrueFalseAnswer.t()
            | ClozeAnswer.t()
            | EmqAnswer.t()

    @doc """
    Convert a map to the appropriate processed answer struct.

    Takes a map (typically from JSON decoding or form submission) and converts it
    to the corresponding answer type struct based on the "answer_type" field.
    """
    def from_map(data) when is_map(data) do
      # Normalize keys to strings for consistent access
      normalized_data =
        for {key, value} <- data, into: %{} do
          {to_string(key), value}
        end

      answer_type = normalized_data["answer_type"]

      case answer_type do
        "mcq_single" ->
          selected_index = normalized_data["selected_index"]
          if is_nil(selected_index) do
            raise ArgumentError, "MCQ single answer requires selected_index"
          end
          %McqSingleAnswer{
            selected_index: selected_index
          }

        "mcq_multi" ->
          selected_indices = normalized_data["selected_indices"]
          if is_nil(selected_indices) do
            raise ArgumentError, "MCQ multi answer requires selected_indices"
          end
          %McqMultiAnswer{
            selected_indices: selected_indices
          }

        "written" ->
          text = normalized_data["text"] || normalized_data["answer_text"]
          if is_nil(text) do
            raise ArgumentError, "Written answer requires text or answer_text"
          end
          %WrittenAnswer{
            text: text
          }

        "true_false" ->
          selected = if Map.has_key?(normalized_data, "selected") do
            normalized_data["selected"]
          else
            normalized_data["is_true"]
          end
          if is_nil(selected) do
            raise ArgumentError, "True/false answer requires selected or is_true"
          end
          %TrueFalseAnswer{
            selected: selected
          }

        "cloze" ->
          answers = normalized_data["answers"]
          if is_nil(answers) do
            raise ArgumentError, "Cloze answer requires answers"
          end
          %ClozeAnswer{
            answers: answers
          }

        "emq" ->
          matches = normalized_data["matches"]
          if is_nil(matches) do
            raise ArgumentError, "EMQ answer requires matches"
          end
          %EmqAnswer{
            matches: matches
          }

        nil ->
          raise KeyError, key: "answer_type", term: normalized_data

        unknown_type ->
          raise RuntimeError, "Unknown answer type: #{unknown_type}"
      end
    end

    @doc """
    Convert a processed answer struct to a map.
    """
    def to_map(answer) do
      answer
      |> Map.from_struct()
      |> Map.delete(:__struct__)
    end
  end

  defmodule Question do
    @moduledoc """
    Contains all processed question type structs and conversion functions.

    Each question type struct represents the final, processed format of a question
    that will be stored in the database. All structs include:
    - `question_text`: The main question prompt
    - `difficulty`: Difficulty level (e.g., "easy", "medium", "hard")
    - `retention_aid`: Optional text to help with retention/recall
    - `explanation`: Optional explanation for the question/answer
    - `question_type`: Auto-set type identifier
    """

    defmodule McqSingle do
      @moduledoc """
      Multiple Choice Question with a single correct answer.

      ## Fields
      - `question_text`: The question prompt
      - `options`: List of answer choices as strings
      - `correct_index`: Zero-based index of the correct option
      - `difficulty`: Difficulty level
      - `retention_aid`: Optional memory aid text
      - `explanation`: Optional explanation text
      - `question_type`: Always "mcq_single"

      ## Example
          %McqSingle{
            question_text: "What is the capital of France?",
            options: ["Berlin", "Paris", "London"],
            correct_index: 1,
            difficulty: "easy",
            retention_aid: "Think about major European capitals",
            explanation: "Paris is the capital city of France."
          }
      """
      @enforce_keys [:question_text, :options, :correct_index, :difficulty]
      defstruct [
        :question_text,
        :options,
        :correct_index,
        :explanation,
        :difficulty,
        :retention_aid,
        question_type: "mcq_single"
      ]

      @type t :: %__MODULE__{
              question_text: String.t(),
              options: [String.t()],
              correct_index: non_neg_integer,
              explanation: String.t() | nil,
              difficulty: String.t(),
              retention_aid: String.t() | nil,
              question_type: String.t()
            }
    end

    defmodule McqMulti do
      @moduledoc """
      Multiple Choice Question with multiple correct answers.

      ## Fields
      - `question_text`: The question prompt
      - `options`: List of answer choices as strings
      - `correct_indices`: List of zero-based indices of all correct options
      - `difficulty`: Difficulty level
      - `retention_aid`: Optional memory aid text
      - `explanation`: Optional explanation text
      - `question_type`: Always "mcq_multi"

      ## Example
          %McqMulti{
            question_text: "Which are primary colors?",
            options: ["Red", "Green", "Blue", "Yellow"],
            correct_indices: [0, 2, 3],
            difficulty: "medium",
            retention_aid: "Remember the color wheel basics",
            explanation: "Red, blue, and yellow are primary colors."
          }
      """
      @enforce_keys [:question_text, :options, :correct_indices, :difficulty]
      defstruct [
        :question_text,
        :options,
        :correct_indices,
        :explanation,
        :difficulty,
        :retention_aid,
        question_type: "mcq_multi"
      ]

      @type t :: %__MODULE__{
              question_text: String.t(),
              options: [String.t()],
              correct_indices: [non_neg_integer],
              explanation: String.t() | nil,
              difficulty: String.t(),
              retention_aid: String.t() | nil,
              question_type: String.t()
            }
    end

    defmodule Written do
      @moduledoc """
      Open-ended written response question.

      ## Fields
      - `question_text`: The question prompt
      - `correct_answer`: Optional model answer or key points
      - `difficulty`: Difficulty level
      - `retention_aid`: Optional memory aid text
      - `explanation`: Optional explanation text
      - `question_type`: Always "written"

      ## Example
          %Written{
            question_text: "Explain photosynthesis in your own words.",
            correct_answer: "Process where plants convert light into chemical energy",
            difficulty: "hard",
            retention_aid: "Think about how plants make food from sunlight",
            explanation: "Key concepts: light energy, chlorophyll, glucose production."
          }
      """
      @enforce_keys [:question_text, :difficulty]
      defstruct [
        :question_text,
        :correct_answer,
        :explanation,
        :difficulty,
        :retention_aid,
        question_type: "written"
      ]

      @type t :: %__MODULE__{
              question_text: String.t(),
              correct_answer: String.t() | nil,
              explanation: String.t() | nil,
              difficulty: String.t(),
              retention_aid: String.t() | nil,
              question_type: String.t()
            }
    end

    defmodule TrueFalse do
      @moduledoc """
      True/False question with a boolean answer.

      ## Fields
      - `question_text`: The statement to evaluate
      - `is_correct_true`: Whether the statement is true (true) or false (false)
      - `difficulty`: Difficulty level
      - `retention_aid`: Optional memory aid text
      - `explanation`: Optional explanation text
      - `question_type`: Always "true_false"

      ## Example
          %TrueFalse{
            question_text: "The Earth is flat.",
            is_correct_true: false,
            difficulty: "easy",
            retention_aid: "Consider what we know about Earth's shape from space",
            explanation: "The Earth is an oblate spheroid, not flat."
          }
      """
      @enforce_keys [:question_text, :is_correct_true, :difficulty]
      defstruct [
        :question_text,
        :is_correct_true,
        :explanation,
        :difficulty,
        :retention_aid,
        question_type: "true_false"
      ]

      @type t :: %__MODULE__{
              question_text: String.t(),
              is_correct_true: boolean(),
              explanation: String.t() | nil,
              difficulty: String.t(),
              retention_aid: String.t() | nil,
              question_type: String.t()
            }
    end

    defmodule Cloze do
      @moduledoc """
      Fill-in-the-blanks question with multiple gaps to complete.

      ## Fields
      - `question_text`: Text with blanks in format `{{c1::hint}}`, `{{c2::hint}}`, etc.
      - `answers`: List of correct answers for each blank (c1 = answers[0], c2 = answers[1], etc.)
      - `difficulty`: Difficulty level
      - `retention_aid`: Optional memory aid text
      - `explanation`: Optional explanation text
      - `question_type`: Always "cloze"

      ## Format
      The question_text contains hints inline using `{{c#::hint}}` format where:
      - `c#` is the blank number (c1, c2, c3, etc.)
      - `hint` is optional text to help the user (can be empty)
      - Actual answers are stored separately in the `answers` array

      ## Example
          %Cloze{
            question_text: "In {{c1::major conflicts}} and {{c2::negotiations}}, there is a {{c3::mediator role}}.",
            answers: ["wars", "treaties", "role"],
            difficulty: "medium",
            retention_aid: "Think about conflict resolution",
            explanation: "This describes international diplomacy processes."
          }

      ## Usage in Code
          ZiStudy.Questions.create_question(%Cloze{
            question_text: "In {{c1::hint1}} and {{c2::hint2}}, there is a {{c3::hint3}}.",
            difficulty: "medium",
            retention_aid: "Some retention aid",
            answers: ["answer1", "answer2", "answer3"]
          })
      """
      @enforce_keys [:question_text, :answers, :difficulty]
      defstruct [
        :question_text,
        :answers,
        :explanation,
        :difficulty,
        :retention_aid,
        question_type: "cloze"
      ]

      @type t :: %__MODULE__{
              question_text: String.t(),
              answers: [String.t()],
              explanation: String.t() | nil,
              difficulty: String.t(),
              retention_aid: String.t() | nil,
              question_type: String.t()
            }
    end

    defmodule Emq do
      @moduledoc """
      Extended Matching Question - match premises to options.

      ## Fields
      - `instructions`: Instructions for the matching task
      - `premises`: List of items/stems to be matched
      - `options`: List of possible answer choices
      - `matches`: List of tuples `{premise_index, option_index}` for correct matches
      - `difficulty`: Difficulty level
      - `retention_aid`: Optional memory aid text
      - `explanation`: Optional explanation text
      - `question_type`: Always "emq"

      ## Example
          %Emq{
            instructions: "Match each symptom to the correct drug class.",
            premises: ["Dry cough", "Bradycardia"],
            options: ["ACE Inhibitor", "Beta Blocker", "Calcium Channel Blocker"],
            matches: [[0, 0], [1, 1]],  # Dry cough -> ACE Inhibitor, Bradycardia -> Beta Blocker
            difficulty: "hard",
            retention_aid: "Remember drug side effects and contraindications",
            explanation: "ACE inhibitors can cause dry cough, beta blockers can cause bradycardia."
          }
      """
      @enforce_keys [:premises, :options, :difficulty]
      defstruct [
        :instructions,
        :premises,
        :options,
        :matches,
        :explanation,
        :difficulty,
        :retention_aid,
        question_type: "emq"
      ]

      @type t :: %__MODULE__{
              instructions: String.t() | nil,
              premises: [String.t()],
              options: [String.t()],
              matches: [[non_neg_integer]] | nil,
              explanation: String.t() | nil,
              difficulty: String.t(),
              retention_aid: String.t() | nil,
              question_type: String.t()
            }
    end

    @type t ::
            McqSingle.t()
            | McqMulti.t()
            | Written.t()
            | TrueFalse.t()
            | Cloze.t()
            | Emq.t()

    @doc """
    Convert a map to the appropriate processed content struct.

    Takes a map (typically from JSON decoding or database retrieval) and converts it
    to the corresponding question type struct based on the "question_type" field.

    ## Parameters
    - `data`: Map containing question data with string or atom keys

    ## Returns
    - Processed question struct of the appropriate type

    ## Examples
        iex> data = %{
        ...>   "question_type" => "mcq_single",
        ...>   "question_text" => "What is 2+2?",
        ...>   "options" => ["3", "4", "5"],
        ...>   "correct_index" => 1,
        ...>   "difficulty" => "easy"
        ...> }
        iex> Processed.Question.from_map(data)
        %Processed.Question.McqSingle{
          question_text: "What is 2+2?",
          options: ["3", "4", "5"],
          correct_index: 1,
          difficulty: "easy",
          retention_aid: nil,
          explanation: nil,
          question_type: "mcq_single"
        }
    """
    @spec from_map(map()) :: t()
    def from_map(data) when is_map(data) do
      # Normalize keys to strings for consistent access
      normalized_data =
        case data do
          %{} when map_size(data) == 0 ->
            %{}

          _ ->
            for {key, value} <- data, into: %{} do
              {to_string(key), value}
            end
        end

      question_type = normalized_data["question_type"]

      case question_type do
        "mcq_single" ->
          %McqSingle{
            question_text: normalized_data["question_text"],
            options: normalized_data["options"],
            correct_index: normalized_data["correct_index"],
            explanation: normalized_data["explanation"],
            difficulty: normalized_data["difficulty"],
            retention_aid: normalized_data["retention_aid"]
          }

        "mcq_multi" ->
          %McqMulti{
            question_text: normalized_data["question_text"],
            options: normalized_data["options"],
            correct_indices: normalized_data["correct_indices"],
            explanation: normalized_data["explanation"],
            difficulty: normalized_data["difficulty"],
            retention_aid: normalized_data["retention_aid"]
          }

        "written" ->
          %Written{
            question_text: normalized_data["question_text"],
            correct_answer: normalized_data["correct_answer"],
            explanation: normalized_data["explanation"],
            difficulty: normalized_data["difficulty"],
            retention_aid: normalized_data["retention_aid"]
          }

        "true_false" ->
          %TrueFalse{
            question_text: normalized_data["question_text"],
            is_correct_true: normalized_data["is_correct_true"],
            explanation: normalized_data["explanation"],
            difficulty: normalized_data["difficulty"],
            retention_aid: normalized_data["retention_aid"]
          }

        "cloze" ->
          %Cloze{
            question_text: normalized_data["question_text"],
            answers: normalized_data["answers"],
            explanation: normalized_data["explanation"],
            difficulty: normalized_data["difficulty"],
            retention_aid: normalized_data["retention_aid"]
          }

        "emq" ->
          %Emq{
            instructions: normalized_data["instructions"],
            premises: normalized_data["premises"],
            options: normalized_data["options"],
            matches: normalized_data["matches"],
            explanation: normalized_data["explanation"],
            difficulty: normalized_data["difficulty"],
            retention_aid: normalized_data["retention_aid"]
          }

        nil ->
          raise KeyError, key: "question_type", term: normalized_data

        unknown_type ->
          raise RuntimeError, "Unknown question type: #{unknown_type}"
      end
    end

    @doc """
    Convert a processed content struct to a map.

    Takes any processed question struct and converts it to a map representation,
    removing the internal `__struct__` field for clean serialization.

    ## Parameters
    - `content`: Any processed question struct

    ## Returns
    - Map with atom keys representing the struct fields

    ## Examples
        iex> question = %Processed.Question.McqSingle{
        ...>   question_text: "What is 2+2?",
        ...>   options: ["3", "4", "5"],
        ...>   correct_index: 1,
        ...>   difficulty: "easy"
        ...> }
        iex> Processed.Question.to_map(question)
        %{
          question_text: "What is 2+2?",
          options: ["3", "4", "5"],
          correct_index: 1,
          difficulty: "easy",
          retention_aid: nil,
          explanation: nil,
          question_type: "mcq_single"
        }
    """
    @spec to_map(t()) :: map()
    def to_map(content) do
      content
      |> Map.from_struct()
      |> Map.delete(:__struct__)
    end
  end
end
