defmodule ZiStudy.QuestionsOps.Import do
  defmodule Question do
    @moduledoc """
    Defines structs for question import data
    """

    defmodule McqOption do
      @enforce_keys [:temp_id, :text]
      defstruct [:temp_id, :text]
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
    end

    defmodule EmqPremise do
      @enforce_keys [:temp_id, :text]
      defstruct [:temp_id, :text]
    end

    defmodule EmqOption do
      @enforce_keys [:temp_id, :text]
      defstruct [:temp_id, :text]
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
    end

    @type temp_id :: String.t() | atom()
    @type t :: McqSingle.t() | McqMulti.t() | Written.t() | TrueFalse.t() | Cloze.t() | Emq.t()
  end
end
