defmodule ZiStudy.QuestionsOps.JsonSerializer do
  @moduledoc """
  Handles JSON serialization/deserialization for question content
  """
  alias ZiStudy.QuestionsOps.Processed.Question, as: QuestionContent
  alias ZiStudy.QuestionsOps.Import.Question, as: QuestionImport

  @doc """
  Deserialize a JSON string representing a single question into an import struct.
  """
  def deserialize_import(json_string) do
    json_string
    |> Jason.decode!()
    |> map_to_import_struct()
  end

  @doc """
  Deserialize a JSON string representing a list of questions into a list of import structs.
  """
  def deserialize_import_list(json_list_string) do
    json_list_string
    |> Jason.decode!()
    |> Enum.map(&map_to_import_struct/1)
  end

  @doc """
  Converts a map (typically from JSON decoding) into the appropriate question import struct.
  """
  @spec map_to_import_struct(map()) :: QuestionImport.t() | no_return()
  def map_to_import_struct(data) do
    case data["question_type"] do
      "mcq-single" ->
        %QuestionImport.McqSingle{
          temp_id: data["temp_id"],
          question_type: data["question_type"],
          difficulty: data["difficulty"],
          question_text: data["question_text"],
          retention_aid: data["retention_aid"],
          options: Enum.map(data["options"], &struct!(QuestionImport.McqOption, &1)),
          correct_option_temp_id: data["correct_option_temp_id"],
          explanation: data["explanation"]
        }

      "mcq-multi" ->
        %QuestionImport.McqMulti{
          temp_id: data["temp_id"],
          question_type: data["question_type"],
          difficulty: data["difficulty"],
          question_text: data["question_text"],
          retention_aid: data["retention_aid"],
          options: Enum.map(data["options"], &struct!(QuestionImport.McqOption, &1)),
          correct_option_temp_ids: data["correct_option_temp_ids"],
          explanation: data["explanation"]
        }

      "written" ->
        %QuestionImport.Written{
          temp_id: data["temp_id"],
          question_type: data["question_type"],
          difficulty: data["difficulty"],
          question_text: data["question_text"],
          retention_aid: data["retention_aid"],
          correct_answer_text: data["correct_answer_text"],
          explanation: data["explanation"]
        }

      "true-false" ->
        %QuestionImport.TrueFalse{
          temp_id: data["temp_id"],
          question_type: data["question_type"],
          difficulty: data["difficulty"],
          question_text: data["question_text"],
          retention_aid: data["retention_aid"],
          is_correct_true: data["is_correct_true"],
          explanation: data["explanation"]
        }

      "cloze" ->
        %QuestionImport.Cloze{
          temp_id: data["temp_id"],
          question_type: data["question_type"],
          difficulty: data["difficulty"],
          question_text: data["question_text"],
          retention_aid: data["retention_aid"],
          answers: data["answers"],
          explanation: data["explanation"]
        }

      "emq" ->
        %QuestionImport.Emq{
          temp_id: data["temp_id"],
          question_type: data["question_type"],
          difficulty: data["difficulty"],
          instructions: data["instructions"],
          retention_aid: data["retention_aid"],
          premises: Enum.map(data["premises"], &struct!(QuestionImport.EmqPremise, &1)),
          options: Enum.map(data["options"], &struct!(QuestionImport.EmqOption, &1)),
          matches: Enum.map(data["matches"], fn [p, o] -> {p, o} end),
          explanation: data["explanation"]
        }

      type ->
        raise "Unknown question type for import: #{type}"
    end
  end

  @doc """
  Serialize processed content to JSON
  """
  def serialize_processed(content) do
    content
    |> QuestionContent.to_map()
    |> Jason.encode!()
  end

  @doc """
  Deserialize processed content from JSON
  """
  def deserialize_processed(json) do
    json
    |> Jason.decode!()
    |> QuestionContent.from_map()
  end
end
