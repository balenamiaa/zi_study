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
              difficulty: String.t() | nil,
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
              difficulty: String.t() | nil,
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
              difficulty: String.t() | nil,
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
              difficulty: String.t() | nil,
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
              difficulty: String.t() | nil,
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
              matches: [{non_neg_integer, non_neg_integer}] | nil,
              explanation: String.t() | nil,
              difficulty: String.t() | nil,
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
    def from_map(%{"question_type" => question_type} = data) do
      case question_type do
        "mcq_single" ->
          %McqSingle{
            question_text: data["question_text"],
            options: data["options"],
            correct_index: data["correct_index"],
            explanation: data["explanation"],
            difficulty: data["difficulty"]
          }

        "mcq_multi" ->
          %McqMulti{
            question_text: data["question_text"],
            options: data["options"],
            correct_indices: data["correct_indices"],
            explanation: data["explanation"],
            difficulty: data["difficulty"]
          }

        "written" ->
          %Written{
            question_text: data["question_text"],
            correct_answer: data["correct_answer"],
            explanation: data["explanation"],
            difficulty: data["difficulty"]
          }

        "true_false" ->
          %TrueFalse{
            question_text: data["question_text"],
            is_correct_true: data["is_correct_true"],
            explanation: data["explanation"],
            difficulty: data["difficulty"]
          }

        "cloze" ->
          %Cloze{
            question_text: data["question_text"],
            answers: data["answers"],
            explanation: data["explanation"],
            difficulty: data["difficulty"]
          }

        "emq" ->
          %Emq{
            instructions: data["instructions"],
            premises: data["premises"],
            options: data["options"],
            matches: data["matches"],
            explanation: data["explanation"],
            difficulty: data["difficulty"]
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
