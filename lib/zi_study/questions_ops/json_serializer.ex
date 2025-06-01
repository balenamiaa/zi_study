defmodule ZiStudy.QuestionsOps.JsonSerializer do
  @moduledoc """
  Handles JSON serialization/deserialization for question content
  """
  alias ZiStudy.QuestionsOps.Processed.Question, as: QuestionContent
  alias ZiStudy.QuestionsOps.Import.Question, as: QuestionImport

  @doc """
  Deserialize JSON to import structs
  """
  def deserialize_import(json) do
    Jason.decode!(json)
    |> parse_import_data()
  end

  defp parse_import_data(data) do
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
