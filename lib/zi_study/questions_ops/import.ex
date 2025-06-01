defmodule ZiStudy.QuestionsOps.Import do
  defmodule Question do
    @moduledoc """
    Defines structs for question import data
    """

    defmodule McqOption do
      @enforce_keys [:temp_id, :text]
      defstruct [:temp_id, :text]

      @type t :: %__MODULE__{
              temp_id: String.t() | atom(),
              text: String.t()
            }
    end

    defmodule McqSingle do
      @enforce_keys [
        :temp_id,
        :question_type,
        :difficulty,
        :question_text,
        :options,
        :correct_option_temp_id
      ]

      defstruct [
        :temp_id,
        :question_type,
        :difficulty,
        :question_text,
        :retention_aid,
        :options,
        :correct_option_temp_id,
        :explanation
      ]

      @type t :: %__MODULE__{
              temp_id: String.t() | atom(),
              question_type: String.t(),
              difficulty: String.t(),
              question_text: String.t(),
              retention_aid: String.t() | nil,
              options: [McqOption.t()],
              correct_option_temp_id: String.t() | atom(),
              explanation: String.t() | nil
            }
    end

    defmodule McqMulti do
      @enforce_keys [
        :temp_id,
        :question_type,
        :difficulty,
        :question_text,
        :options,
        :correct_option_temp_ids
      ]

      defstruct [
        :temp_id,
        :question_type,
        :difficulty,
        :question_text,
        :retention_aid,
        :options,
        :correct_option_temp_ids,
        :explanation
      ]

      @type t :: %__MODULE__{
              temp_id: String.t() | atom(),
              question_type: String.t(),
              difficulty: String.t(),
              question_text: String.t(),
              retention_aid: String.t() | nil,
              options: [McqOption.t()],
              correct_option_temp_ids: [String.t() | atom()],
              explanation: String.t() | nil
            }
    end

    defmodule Written do
      @enforce_keys [
        :temp_id,
        :question_type,
        :difficulty,
        :question_text,
        :correct_answer_text
      ]

      defstruct [
        :temp_id,
        :question_type,
        :difficulty,
        :question_text,
        :retention_aid,
        :correct_answer_text,
        :explanation
      ]

      @type t :: %__MODULE__{
              temp_id: String.t() | atom(),
              question_type: String.t(),
              difficulty: String.t(),
              question_text: String.t(),
              retention_aid: String.t() | nil,
              correct_answer_text: String.t(),
              explanation: String.t() | nil
            }
    end

    defmodule TrueFalse do
      @enforce_keys [
        :temp_id,
        :question_type,
        :difficulty,
        :question_text,
        :is_correct_true
      ]

      defstruct [
        :temp_id,
        :question_type,
        :difficulty,
        :question_text,
        :retention_aid,
        :is_correct_true,
        :explanation
      ]

      @type t :: %__MODULE__{
              temp_id: String.t() | atom(),
              question_type: String.t(),
              difficulty: String.t(),
              question_text: String.t(),
              retention_aid: String.t() | nil,
              is_correct_true: boolean(),
              explanation: String.t() | nil
            }
    end

    defmodule Cloze do
      @enforce_keys [
        :temp_id,
        :question_type,
        :difficulty,
        :question_text,
        :answers
      ]

      defstruct [
        :temp_id,
        :question_type,
        :difficulty,
        :question_text,
        :retention_aid,
        :answers,
        :explanation
      ]

      @type t :: %__MODULE__{
              temp_id: String.t() | atom(),
              question_type: String.t(),
              difficulty: String.t(),
              question_text: String.t(),
              retention_aid: String.t() | nil,
              answers: [String.t()],
              explanation: String.t() | nil
            }
    end

    defmodule EmqPremise do
      @enforce_keys [:temp_id, :text]
      defstruct [:temp_id, :text]

      @type t :: %__MODULE__{
              temp_id: String.t() | atom(),
              text: String.t()
            }
    end

    defmodule EmqOption do
      @enforce_keys [:temp_id, :text]
      defstruct [:temp_id, :text]

      @type t :: %__MODULE__{
              temp_id: String.t() | atom(),
              text: String.t()
            }
    end

    defmodule Emq do
      @enforce_keys [
        :temp_id,
        :question_type,
        :difficulty,
        :instructions,
        :premises,
        :options,
        :matches
      ]

      defstruct [
        :temp_id,
        :question_type,
        :difficulty,
        :instructions,
        :retention_aid,
        :premises,
        :options,
        :matches,
        :explanation
      ]

      @type t :: %__MODULE__{
              temp_id: String.t() | atom(),
              question_type: String.t(),
              difficulty: String.t(),
              instructions: String.t(),
              retention_aid: String.t() | nil,
              premises: [EmqPremise.t()],
              options: [EmqOption.t()],
              matches: [{String.t() | atom(), String.t() | atom()}],
              explanation: String.t() | nil
            }
    end

    @type t :: McqSingle.t() | McqMulti.t() | Written.t() | TrueFalse.t() | Cloze.t() | Emq.t()
  end
end
