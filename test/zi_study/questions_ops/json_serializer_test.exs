defmodule ZiStudy.QuestionsOps.JsonSerializerTest do
  use ExUnit.Case, async: true

  alias ZiStudy.QuestionsOps.JsonSerializer
  alias ZiStudy.QuestionsOps.Processed.Question, as: ProcessedQuestion

  describe "serialize_processed/1" do
    test "serializes MCQ single processed content to JSON" do
      content = %ProcessedQuestion.McqSingle{
        question_text: "What is 2+2?",
        options: ["3", "4", "5"],
        correct_index: 1,
        explanation: "Basic math",
        difficulty: "easy",
        retention_aid: "Numbers"
      }

      json = JsonSerializer.serialize_processed(content)
      decoded = Jason.decode!(json)

      assert decoded["question_type"] == "mcq_single"
      assert decoded["question_text"] == "What is 2+2?"
      assert decoded["options"] == ["3", "4", "5"]
      assert decoded["correct_index"] == 1
      assert decoded["difficulty"] == "easy"
      assert decoded["explanation"] == "Basic math"
      assert decoded["retention_aid"] == "Numbers"
    end

    test "serializes true/false processed content to JSON" do
      content = %ProcessedQuestion.TrueFalse{
        question_text: "The sky is blue",
        is_correct_true: true,
        explanation: "Light scattering",
        difficulty: "easy",
        retention_aid: nil
      }

      json = JsonSerializer.serialize_processed(content)
      decoded = Jason.decode!(json)

      assert decoded["question_type"] == "true_false"
      assert decoded["question_text"] == "The sky is blue"
      assert decoded["is_correct_true"] == true
      assert decoded["retention_aid"] == nil
      assert decoded["explanation"] == "Light scattering"
    end

    test "serializes written question processed content to JSON" do
      content = %ProcessedQuestion.Written{
        question_text: "Explain photosynthesis",
        correct_answer: "Process converting light to energy",
        explanation: "Uses chlorophyll",
        difficulty: "hard",
        retention_aid: "Biology"
      }

      json = JsonSerializer.serialize_processed(content)
      decoded = Jason.decode!(json)

      assert decoded["question_type"] == "written"
      assert decoded["question_text"] == "Explain photosynthesis"
      assert decoded["correct_answer"] == "Process converting light to energy"
      assert decoded["difficulty"] == "hard"
    end

    test "serializes cloze question processed content to JSON" do
      content = %ProcessedQuestion.Cloze{
        question_text: "The capital of France is ____",
        answers: ["Paris", "paris"],
        explanation: "Paris is the capital",
        difficulty: "medium",
        retention_aid: "Geography"
      }

      json = JsonSerializer.serialize_processed(content)
      decoded = Jason.decode!(json)

      assert decoded["question_type"] == "cloze"
      assert decoded["question_text"] == "The capital of France is ____"
      assert decoded["answers"] == ["Paris", "paris"]
      assert decoded["difficulty"] == "medium"
    end

    test "serializes MCQ multi processed content to JSON" do
      content = %ProcessedQuestion.McqMulti{
        question_text: "Select all prime numbers",
        options: ["2", "3", "4", "5"],
        correct_indices: [0, 1, 3],
        explanation: "2, 3, and 5 are prime",
        difficulty: "medium",
        retention_aid: "Math"
      }

      json = JsonSerializer.serialize_processed(content)
      decoded = Jason.decode!(json)

      assert decoded["question_type"] == "mcq_multi"
      assert decoded["question_text"] == "Select all prime numbers"
      assert decoded["options"] == ["2", "3", "4", "5"]
      assert decoded["correct_indices"] == [0, 1, 3]
    end
  end

  describe "deserialize_processed/1" do
    test "deserializes MCQ single from JSON to processed content" do
      json = Jason.encode!(%{
        "question_type" => "mcq_single",
        "question_text" => "What is 2+2?",
        "options" => ["3", "4", "5"],
        "correct_index" => 1,
        "explanation" => "Basic math",
        "difficulty" => "easy",
        "retention_aid" => "Numbers"
      })

      result = JsonSerializer.deserialize_processed(json)

      assert %ProcessedQuestion.McqSingle{} = result
      assert result.question_text == "What is 2+2?"
      assert result.options == ["3", "4", "5"]
      assert result.correct_index == 1
      assert result.difficulty == "easy"
    end

    test "deserializes true/false from JSON to processed content" do
      json = Jason.encode!(%{
        "question_type" => "true_false",
        "question_text" => "The sky is blue",
        "is_correct_true" => true,
        "explanation" => "Light scattering",
        "difficulty" => "easy"
      })

      result = JsonSerializer.deserialize_processed(json)

      assert %ProcessedQuestion.TrueFalse{} = result
      assert result.question_text == "The sky is blue"
      assert result.is_correct_true == true
    end

    test "deserializes written question from JSON to processed content" do
      json = Jason.encode!(%{
        "question_type" => "written",
        "question_text" => "Explain photosynthesis",
        "correct_answer" => "Process converting light to energy",
        "explanation" => "Uses chlorophyll",
        "difficulty" => "hard"
      })

      result = JsonSerializer.deserialize_processed(json)

      assert %ProcessedQuestion.Written{} = result
      assert result.question_text == "Explain photosynthesis"
      assert result.correct_answer == "Process converting light to energy"
    end

    test "deserializes cloze question from JSON to processed content" do
      json = Jason.encode!(%{
        "question_type" => "cloze",
        "question_text" => "The capital of France is ____",
        "answers" => ["Paris", "paris"],
        "explanation" => "Paris is the capital",
        "difficulty" => "medium"
      })

      result = JsonSerializer.deserialize_processed(json)

      assert %ProcessedQuestion.Cloze{} = result
      assert result.question_text == "The capital of France is ____"
      assert result.answers == ["Paris", "paris"]
    end

    test "handles round-trip serialization" do
      original_content = %ProcessedQuestion.McqSingle{
        question_text: "Round trip test?",
        options: ["A", "B", "C"],
        correct_index: 2,
        explanation: "C is correct",
        difficulty: "medium",
        retention_aid: "Test memory"
      }

      # Serialize then deserialize
      json = JsonSerializer.serialize_processed(original_content)
      deserialized = JsonSerializer.deserialize_processed(json)

      assert deserialized == original_content
    end

    test "raises error for invalid JSON in deserialize_processed" do
      invalid_json = "invalid json"

      assert_raise Jason.DecodeError, fn ->
        JsonSerializer.deserialize_processed(invalid_json)
      end
    end

    test "raises error for unknown question type in deserialize_processed" do
      json = Jason.encode!(%{
        "question_type" => "unknown_type",
        "question_text" => "Unknown question"
      })

      assert_raise RuntimeError, "Unknown question type: unknown_type", fn ->
        JsonSerializer.deserialize_processed(json)
      end
    end
  end

  describe "error handling and edge cases" do
    test "handles nil values gracefully in serialization" do
      content = %ProcessedQuestion.TrueFalse{
        question_text: "Test question",
        is_correct_true: false,
        explanation: nil,
        difficulty: "easy",
        retention_aid: nil
      }

      json = JsonSerializer.serialize_processed(content)
      decoded = Jason.decode!(json)

      assert decoded["explanation"] == nil
      assert decoded["retention_aid"] == nil
    end

    test "handles empty collections gracefully" do
      content = %ProcessedQuestion.McqSingle{
        question_text: "Empty options test",
        options: [],
        correct_index: 0,
        explanation: "Test",
        difficulty: "easy",
        retention_aid: nil
      }

      json = JsonSerializer.serialize_processed(content)
      decoded = Jason.decode!(json)

      assert decoded["options"] == []
    end

    test "round-trip preserves all question types correctly" do
      questions = [
        %ProcessedQuestion.McqSingle{
          question_text: "MCQ Single",
          options: ["A", "B"],
          correct_index: 0,
          explanation: "A is correct",
          difficulty: "easy",
          retention_aid: nil
        },
        %ProcessedQuestion.TrueFalse{
          question_text: "True/False",
          is_correct_true: true,
          explanation: "It's true",
          difficulty: "easy",
          retention_aid: nil
        },
        %ProcessedQuestion.Written{
          question_text: "Written",
          correct_answer: "Answer",
          explanation: "Explanation",
          difficulty: "medium",
          retention_aid: "Memory"
        },
        %ProcessedQuestion.Cloze{
          question_text: "Fill ____",
          answers: ["blank"],
          explanation: "Fill in the blank",
          difficulty: "medium",
          retention_aid: nil
        }
      ]

      for original <- questions do
        json = JsonSerializer.serialize_processed(original)
        deserialized = JsonSerializer.deserialize_processed(json)
        assert deserialized == original
      end
    end
  end
end
