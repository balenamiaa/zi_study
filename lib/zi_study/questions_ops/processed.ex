defmodule ZiStudy.QuestionsOps.Processed do
  defmodule Question do
    @moduledoc """
    Defines structs for processed question content (stored in DB)
    """

    defmodule McqSingle do
      @enforce_keys [:question_text, :options, :correct_index, :difficulty]
      defstruct [
        :question_text,
        :options,
        :correct_index,
        :explanation,
        :difficulty,
        question_type: "mcq_single"
      ]

      @type t :: %__MODULE__{
              question_text: String.t(),
              options: [String.t()],
              correct_index: non_neg_integer,
              explanation: String.t() | nil,
              difficulty: String.t(),
              question_type: String.t()
            }
    end

    defmodule McqMulti do
      @enforce_keys [:question_text, :options, :correct_indices, :difficulty]
      defstruct [
        :question_text,
        :options,
        :correct_indices,
        :explanation,
        :difficulty,
        question_type: "mcq_multi"
      ]

      @type t :: %__MODULE__{
              question_text: String.t(),
              options: [String.t()],
              correct_indices: [non_neg_integer],
              explanation: String.t() | nil,
              difficulty: String.t(),
              question_type: String.t()
            }
    end

    defmodule Written do
      @enforce_keys [:question_text, :difficulty]
      defstruct [
        :question_text,
        :correct_answer,
        :explanation,
        :difficulty,
        question_type: "written"
      ]

      @type t :: %__MODULE__{
              question_text: String.t(),
              correct_answer: String.t() | nil,
              explanation: String.t() | nil,
              difficulty: String.t(),
              question_type: String.t()
            }
    end

    defmodule TrueFalse do
      @enforce_keys [:question_text, :is_correct_true, :difficulty]
      defstruct [
        :question_text,
        :is_correct_true,
        :explanation,
        :difficulty,
        question_type: "true_false"
      ]

      @type t :: %__MODULE__{
              question_text: String.t(),
              is_correct_true: boolean(),
              explanation: String.t() | nil,
              difficulty: String.t(),
              question_type: String.t()
            }
    end

    defmodule Cloze do
      @enforce_keys [:question_text, :answers, :difficulty]
      defstruct [
        :question_text,
        :answers,
        :explanation,
        :difficulty,
        question_type: "cloze"
      ]

      @type t :: %__MODULE__{
              question_text: String.t(),
              answers: [String.t()],
              explanation: String.t() | nil,
              difficulty: String.t(),
              question_type: String.t()
            }
    end

    defmodule Emq do
      @enforce_keys [:premises, :options, :difficulty]
      defstruct [
        :instructions,
        :premises,
        :options,
        :matches,
        :explanation,
        :difficulty,
        question_type: "emq"
      ]

      @type t :: %__MODULE__{
              instructions: String.t() | nil,
              premises: [String.t()],
              options: [String.t()],
              matches: [[non_neg_integer]] | nil,
              explanation: String.t() | nil,
              difficulty: String.t(),
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
    Convert a map to processed content struct
    """
    @spec from_map(map()) :: t()
    def from_map(data) when is_map(data) do
      # Normalize keys to strings for consistent access
      normalized_data =
        case data do
          %{} when map_size(data) == 0 -> %{}
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
            difficulty: normalized_data["difficulty"]
          }

        "mcq_multi" ->
          %McqMulti{
            question_text: normalized_data["question_text"],
            options: normalized_data["options"],
            correct_indices: normalized_data["correct_indices"],
            explanation: normalized_data["explanation"],
            difficulty: normalized_data["difficulty"]
          }

        "written" ->
          %Written{
            question_text: normalized_data["question_text"],
            correct_answer: normalized_data["correct_answer"],
            explanation: normalized_data["explanation"],
            difficulty: normalized_data["difficulty"]
          }

        "true_false" ->
          %TrueFalse{
            question_text: normalized_data["question_text"],
            is_correct_true: normalized_data["is_correct_true"],
            explanation: normalized_data["explanation"],
            difficulty: normalized_data["difficulty"]
          }

        "cloze" ->
          %Cloze{
            question_text: normalized_data["question_text"],
            answers: normalized_data["answers"],
            explanation: normalized_data["explanation"],
            difficulty: normalized_data["difficulty"]
          }

        "emq" ->
          %Emq{
            instructions: normalized_data["instructions"],
            premises: normalized_data["premises"],
            options: normalized_data["options"],
            matches: normalized_data["matches"],
            explanation: normalized_data["explanation"],
            difficulty: normalized_data["difficulty"]
          }
      end
    end

    @doc """
    Convert processed content struct to map
    """
    @spec to_map(t()) :: map()
    def to_map(content) do
      content
      |> Map.from_struct()
      |> Map.delete(:__struct__)
    end
  end
end
