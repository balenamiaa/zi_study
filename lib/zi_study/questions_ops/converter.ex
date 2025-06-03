defmodule ZiStudy.QuestionsOps.Converter do
  @moduledoc """
  Converts between import structs and processed content
  """
  alias ZiStudy.QuestionsOps.Import.Question, as: QuestionImport
  alias ZiStudy.QuestionsOps.Processed.Question, as: QuestionContent

  @doc """
  Convert import struct to processed content
  """
  def to_processed_content(import_data) do
    case import_data do
      %QuestionImport.McqSingle{} = data ->
        correct_index = find_index_by_temp_id(data.options, data.correct_option_temp_id)

        %QuestionContent.McqSingle{
          question_text: data.question_text,
          options: Enum.map(data.options, & &1.text),
          correct_index: correct_index,
          explanation: data.explanation,
          difficulty: data.difficulty,
          retention_aid: data.retention_aid
        }

      %QuestionImport.McqMulti{} = data ->
        correct_indices =
          Enum.map(data.correct_option_temp_ids, &find_index_by_temp_id(data.options, &1))

        %QuestionContent.McqMulti{
          question_text: data.question_text,
          options: Enum.map(data.options, & &1.text),
          correct_indices: correct_indices,
          explanation: data.explanation,
          difficulty: data.difficulty,
          retention_aid: data.retention_aid
        }

      %QuestionImport.Written{} = data ->
        %QuestionContent.Written{
          question_text: data.question_text,
          correct_answer: data.correct_answer_text,
          explanation: data.explanation,
          difficulty: data.difficulty,
          retention_aid: data.retention_aid
        }

      %QuestionImport.TrueFalse{} = data ->
        %QuestionContent.TrueFalse{
          question_text: data.question_text,
          is_correct_true: data.is_correct_true,
          explanation: data.explanation,
          difficulty: data.difficulty,
          retention_aid: data.retention_aid
        }

      %QuestionImport.Cloze{} = data ->
        %QuestionContent.Cloze{
          question_text: data.question_text,
          answers: data.answers,
          explanation: data.explanation,
          difficulty: data.difficulty,
          retention_aid: data.retention_aid
        }

      %QuestionImport.Emq{} = data ->
        %QuestionContent.Emq{
          instructions: data.instructions,
          premises: Enum.map(data.premises, & &1.text),
          options: Enum.map(data.options, & &1.text),
          matches: convert_matches(data.matches, data.premises, data.options),
          explanation: data.explanation,
          difficulty: data.difficulty,
          retention_aid: data.retention_aid
        }
    end
  end

  defp find_index_by_temp_id(collection, temp_id) do
    Enum.find_index(collection, fn item -> item.temp_id == temp_id end)
  end

  defp convert_matches(matches, premises, options) do
    Enum.map(matches, fn {premise_temp_id, option_temp_id} ->
      premise_idx = find_index_by_temp_id(premises, premise_temp_id)
      option_idx = find_index_by_temp_id(options, option_temp_id)
      {premise_idx, option_idx}
    end)
  end
end
