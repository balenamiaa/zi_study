defmodule ZiStudy.QuestionsOps.ConverterTest do
  use ExUnit.Case, async: true

  alias ZiStudy.QuestionsOps.Converter
  alias ZiStudy.QuestionsOps.Import.Question, as: ImportQuestion
  alias ZiStudy.QuestionsOps.Processed.Question, as: ProcessedQuestion

  describe "Converter.to_processed_content/1" do
    test "converts McqSingle import to processed with retention_aid" do
      options = [
        %ImportQuestion.McqOption{temp_id: "opt1", text: "Option A"},
        %ImportQuestion.McqOption{temp_id: "opt2", text: "Option B"},
        %ImportQuestion.McqOption{temp_id: "opt3", text: "Option C"}
      ]

      import_question = %ImportQuestion.McqSingle{
        temp_id: "q1",
        question_type: "mcq_single",
        difficulty: "easy",
        question_text: "What is the answer?",
        retention_aid: "Remember to think carefully",
        options: options,
        correct_option_temp_id: "opt2",
        explanation: "B is correct"
      }

      result = Converter.to_processed_content(import_question)

      assert %ProcessedQuestion.McqSingle{} = result
      assert result.question_text == "What is the answer?"
      assert result.options == ["Option A", "Option B", "Option C"]
      assert result.correct_index == 1
      assert result.explanation == "B is correct"
      assert result.difficulty == "easy"
      assert result.retention_aid == "Remember to think carefully"
    end

    test "converts McqMulti import to processed with retention_aid" do
      options = [
        %ImportQuestion.McqOption{temp_id: "opt1", text: "Option A"},
        %ImportQuestion.McqOption{temp_id: "opt2", text: "Option B"},
        %ImportQuestion.McqOption{temp_id: "opt3", text: "Option C"}
      ]

      import_question = %ImportQuestion.McqMulti{
        temp_id: "q1",
        question_type: "mcq_multi",
        difficulty: "medium",
        question_text: "Which are correct?",
        retention_aid: "Multiple answers possible",
        options: options,
        correct_option_temp_ids: ["opt1", "opt3"],
        explanation: "A and C are correct"
      }

      result = Converter.to_processed_content(import_question)

      assert %ProcessedQuestion.McqMulti{} = result
      assert result.question_text == "Which are correct?"
      assert result.options == ["Option A", "Option B", "Option C"]
      assert result.correct_indices == [0, 2]
      assert result.explanation == "A and C are correct"
      assert result.difficulty == "medium"
      assert result.retention_aid == "Multiple answers possible"
    end

    test "converts Written import to processed with retention_aid" do
      import_question = %ImportQuestion.Written{
        temp_id: "q1",
        question_type: "written",
        difficulty: "hard",
        question_text: "Explain the concept",
        retention_aid: "Think about the fundamentals",
        correct_answer_text: "The concept is...",
        explanation: "This is the explanation"
      }

      result = Converter.to_processed_content(import_question)

      assert %ProcessedQuestion.Written{} = result
      assert result.question_text == "Explain the concept"
      assert result.correct_answer == "The concept is..."
      assert result.explanation == "This is the explanation"
      assert result.difficulty == "hard"
      assert result.retention_aid == "Think about the fundamentals"
    end

    test "converts TrueFalse import to processed with retention_aid" do
      import_question = %ImportQuestion.TrueFalse{
        temp_id: "q1",
        question_type: "true_false",
        difficulty: "easy",
        question_text: "The statement is true",
        retention_aid: "Consider the facts",
        is_correct_true: false,
        explanation: "Actually false"
      }

      result = Converter.to_processed_content(import_question)

      assert %ProcessedQuestion.TrueFalse{} = result
      assert result.question_text == "The statement is true"
      assert result.is_correct_true == false
      assert result.explanation == "Actually false"
      assert result.difficulty == "easy"
      assert result.retention_aid == "Consider the facts"
    end

    test "converts Cloze import to processed with retention_aid" do
      import_question = %ImportQuestion.Cloze{
        temp_id: "q1",
        question_type: "cloze",
        difficulty: "medium",
        question_text: "The capital of France is ____",
        retention_aid: "Think about European capitals",
        answers: ["Paris"],
        explanation: "Paris is the capital"
      }

      result = Converter.to_processed_content(import_question)

      assert %ProcessedQuestion.Cloze{} = result
      assert result.question_text == "The capital of France is ____"
      assert result.answers == ["Paris"]
      assert result.explanation == "Paris is the capital"
      assert result.difficulty == "medium"
      assert result.retention_aid == "Think about European capitals"
    end

    test "converts Emq import to processed with retention_aid" do
      premises = [
        %ImportQuestion.EmqPremise{temp_id: "p1", text: "First item"},
        %ImportQuestion.EmqPremise{temp_id: "p2", text: "Second item"}
      ]

      options = [
        %ImportQuestion.EmqOption{temp_id: "o1", text: "Match A"},
        %ImportQuestion.EmqOption{temp_id: "o2", text: "Match B"}
      ]

      import_question = %ImportQuestion.Emq{
        temp_id: "q1",
        question_type: "emq",
        difficulty: "hard",
        instructions: "Match the items",
        retention_aid: "Think about the relationships",
        premises: premises,
        options: options,
        matches: [{"p1", "o1"}, {"p2", "o2"}],
        explanation: "These are the correct matches"
      }

      result = Converter.to_processed_content(import_question)

      assert %ProcessedQuestion.Emq{} = result
      assert result.instructions == "Match the items"
      assert result.premises == ["First item", "Second item"]
      assert result.options == ["Match A", "Match B"]
      assert result.matches == [[0, 0], [1, 1]]
      assert result.explanation == "These are the correct matches"
      assert result.difficulty == "hard"
      assert result.retention_aid == "Think about the relationships"
    end

    test "converts import with nil retention_aid" do
      options = [
        %ImportQuestion.McqOption{temp_id: "opt1", text: "Option A"},
        %ImportQuestion.McqOption{temp_id: "opt2", text: "Option B"}
      ]

      import_question = %ImportQuestion.McqSingle{
        temp_id: "q1",
        question_type: "mcq_single",
        difficulty: "easy",
        question_text: "What is the answer?",
        retention_aid: nil,
        options: options,
        correct_option_temp_id: "opt1",
        explanation: "A is correct"
      }

      result = Converter.to_processed_content(import_question)

      assert %ProcessedQuestion.McqSingle{} = result
      assert result.retention_aid == nil
    end
  end
end
