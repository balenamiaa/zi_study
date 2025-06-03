defmodule ZiStudy.QuestionsOps.ProcessedTest do
  use ExUnit.Case, async: true

  alias ZiStudy.QuestionsOps.Processed

  describe "Processed.Question.from_map/1" do
    test "creates McqSingle struct from map" do
      map = %{
        "question_type" => "mcq_single",
        "question_text" => "What is 2 + 2?",
        "options" => ["3", "4", "5", "6"],
        "correct_index" => 1,
        "explanation" => "2 + 2 = 4",
        "difficulty" => "easy",
        "retention_aid" => "Remember basic arithmetic"
      }

      result = Processed.Question.from_map(map)

      assert %Processed.Question.McqSingle{} = result
      assert result.question_text == "What is 2 + 2?"
      assert result.options == ["3", "4", "5", "6"]
      assert result.correct_index == 1
      assert result.explanation == "2 + 2 = 4"
      assert result.difficulty == "easy"
      assert result.retention_aid == "Remember basic arithmetic"
      assert result.question_type == "mcq_single"
    end

    test "creates McqMulti struct from map" do
      map = %{
        "question_type" => "mcq_multi",
        "question_text" => "Which are prime numbers?",
        "options" => ["2", "3", "4", "5"],
        "correct_indices" => [0, 1, 3],
        "explanation" => "2, 3, and 5 are prime",
        "difficulty" => "medium",
        "retention_aid" => "Numbers only divisible by 1 and themselves"
      }

      result = Processed.Question.from_map(map)

      assert %Processed.Question.McqMulti{} = result
      assert result.question_text == "Which are prime numbers?"
      assert result.options == ["2", "3", "4", "5"]
      assert result.correct_indices == [0, 1, 3]
      assert result.explanation == "2, 3, and 5 are prime"
      assert result.difficulty == "medium"
      assert result.retention_aid == "Numbers only divisible by 1 and themselves"
      assert result.question_type == "mcq_multi"
    end

    test "creates Written struct from map" do
      map = %{
        "question_type" => "written",
        "question_text" => "Explain gravity",
        "correct_answer" => "Force that attracts objects",
        "explanation" => "Gravity is fundamental",
        "difficulty" => "hard",
        "retention_aid" => "Think about what keeps us on Earth"
      }

      result = Processed.Question.from_map(map)

      assert %Processed.Question.Written{} = result
      assert result.question_text == "Explain gravity"
      assert result.correct_answer == "Force that attracts objects"
      assert result.explanation == "Gravity is fundamental"
      assert result.difficulty == "hard"
      assert result.retention_aid == "Think about what keeps us on Earth"
      assert result.question_type == "written"
    end

    test "creates TrueFalse struct from map" do
      map = %{
        "question_type" => "true_false",
        "question_text" => "The Earth is round",
        "is_correct_true" => true,
        "explanation" => "Earth is spherical",
        "difficulty" => "easy",
        "retention_aid" => "Think about globe shape"
      }

      result = Processed.Question.from_map(map)

      assert %Processed.Question.TrueFalse{} = result
      assert result.question_text == "The Earth is round"
      assert result.is_correct_true == true
      assert result.explanation == "Earth is spherical"
      assert result.difficulty == "easy"
      assert result.retention_aid == "Think about globe shape"
      assert result.question_type == "true_false"
    end

    test "creates Cloze struct from map" do
      map = %{
        "question_type" => "cloze",
        "question_text" => "Paris is the capital of _____",
        "answers" => ["France"],
        "explanation" => "Paris is France's capital",
        "difficulty" => "easy",
        "retention_aid" => "Think about European capitals"
      }

      result = Processed.Question.from_map(map)

      assert %Processed.Question.Cloze{} = result
      assert result.question_text == "Paris is the capital of _____"
      assert result.answers == ["France"]
      assert result.explanation == "Paris is France's capital"
      assert result.difficulty == "easy"
      assert result.retention_aid == "Think about European capitals"
      assert result.question_type == "cloze"
    end

    test "creates Emq struct from map" do
      map = %{
        "question_type" => "emq",
        "instructions" => "Match planets with positions",
        "premises" => ["First planet", "Second planet"],
        "options" => ["Mercury", "Venus", "Earth"],
        "matches" => [{0, 0}, {1, 1}],
        "explanation" => "Mercury is first, Venus is second",
        "difficulty" => "medium",
        "retention_aid" => "Remember solar system order"
      }

      result = Processed.Question.from_map(map)

      assert %Processed.Question.Emq{} = result
      assert result.instructions == "Match planets with positions"
      assert result.premises == ["First planet", "Second planet"]
      assert result.options == ["Mercury", "Venus", "Earth"]
      assert result.matches == [{0, 0}, {1, 1}]
      assert result.explanation == "Mercury is first, Venus is second"
      assert result.difficulty == "medium"
      assert result.retention_aid == "Remember solar system order"
      assert result.question_type == "emq"
    end

    test "creates structs with nil retention_aid when not provided" do
      map = %{
        "question_type" => "mcq_single",
        "question_text" => "What is 2 + 2?",
        "options" => ["3", "4", "5", "6"],
        "correct_index" => 1,
        "explanation" => "2 + 2 = 4",
        "difficulty" => "easy"
      }

      result = Processed.Question.from_map(map)

      assert %Processed.Question.McqSingle{} = result
      assert result.retention_aid == nil
    end
  end

  describe "Processed.Question.to_map/1" do
    test "converts McqSingle struct to map" do
      struct = %Processed.Question.McqSingle{
        question_text: "What is 2 + 2?",
        options: ["3", "4", "5", "6"],
        correct_index: 1,
        explanation: "2 + 2 = 4",
        difficulty: "easy",
        retention_aid: "Basic math reminder"
      }

      result = Processed.Question.to_map(struct)

      expected = %{
        question_text: "What is 2 + 2?",
        options: ["3", "4", "5", "6"],
        correct_index: 1,
        explanation: "2 + 2 = 4",
        difficulty: "easy",
        retention_aid: "Basic math reminder",
        question_type: "mcq_single"
      }

      assert result == expected
    end

    test "converts McqMulti struct to map" do
      struct = %Processed.Question.McqMulti{
        question_text: "Which are prime?",
        options: ["2", "3", "4"],
        correct_indices: [0, 1],
        explanation: "2 and 3 are prime",
        difficulty: "medium",
        retention_aid: "Prime number definition"
      }

      result = Processed.Question.to_map(struct)

      expected = %{
        question_text: "Which are prime?",
        options: ["2", "3", "4"],
        correct_indices: [0, 1],
        explanation: "2 and 3 are prime",
        difficulty: "medium",
        retention_aid: "Prime number definition",
        question_type: "mcq_multi"
      }

      assert result == expected
    end

    test "converts Written struct to map" do
      struct = %Processed.Question.Written{
        question_text: "Explain gravity",
        correct_answer: "A fundamental force",
        explanation: "Gravity attracts masses",
        difficulty: "hard",
        retention_aid: "Physics concept"
      }

      result = Processed.Question.to_map(struct)

      expected = %{
        question_text: "Explain gravity",
        correct_answer: "A fundamental force",
        explanation: "Gravity attracts masses",
        difficulty: "hard",
        retention_aid: "Physics concept",
        question_type: "written"
      }

      assert result == expected
    end

    test "converts TrueFalse struct to map" do
      struct = %Processed.Question.TrueFalse{
        question_text: "The Earth is flat",
        is_correct_true: false,
        explanation: "Earth is spherical",
        difficulty: "easy",
        retention_aid: "Geography fact"
      }

      result = Processed.Question.to_map(struct)

      expected = %{
        question_text: "The Earth is flat",
        is_correct_true: false,
        explanation: "Earth is spherical",
        difficulty: "easy",
        retention_aid: "Geography fact",
        question_type: "true_false"
      }

      assert result == expected
    end

    test "converts Cloze struct to map" do
      struct = %Processed.Question.Cloze{
        question_text: "The capital of France is _____",
        answers: ["Paris"],
        explanation: "Paris is the capital",
        difficulty: "easy",
        retention_aid: "European geography"
      }

      result = Processed.Question.to_map(struct)

      expected = %{
        question_text: "The capital of France is _____",
        answers: ["Paris"],
        explanation: "Paris is the capital",
        difficulty: "easy",
        retention_aid: "European geography",
        question_type: "cloze"
      }

      assert result == expected
    end

    test "converts Emq struct to map" do
      struct = %Processed.Question.Emq{
        instructions: "Match items",
        premises: ["A", "B"],
        options: ["1", "2"],
        matches: [{0, 0}, {1, 1}],
        explanation: "A matches 1, B matches 2",
        difficulty: "medium",
        retention_aid: "Matching concept"
      }

      result = Processed.Question.to_map(struct)

      expected = %{
        instructions: "Match items",
        premises: ["A", "B"],
        options: ["1", "2"],
        matches: [{0, 0}, {1, 1}],
        explanation: "A matches 1, B matches 2",
        difficulty: "medium",
        retention_aid: "Matching concept",
        question_type: "emq"
      }

      assert result == expected
    end

    test "converts struct with nil retention_aid to map" do
      struct = %Processed.Question.McqSingle{
        question_text: "What is 2 + 2?",
        options: ["3", "4", "5", "6"],
        correct_index: 1,
        explanation: "2 + 2 = 4",
        difficulty: "easy",
        retention_aid: nil
      }

      result = Processed.Question.to_map(struct)

      expected = %{
        question_text: "What is 2 + 2?",
        options: ["3", "4", "5", "6"],
        correct_index: 1,
        explanation: "2 + 2 = 4",
        difficulty: "easy",
        retention_aid: nil,
        question_type: "mcq_single"
      }

      assert result == expected
    end
  end

  describe "round-trip conversion" do
    test "McqSingle survives map -> struct -> map conversion" do
      original_map = %{
        "question_type" => "mcq_single",
        "question_text" => "Test question",
        "options" => ["A", "B", "C"],
        "correct_index" => 1,
        "explanation" => "Test explanation",
        "difficulty" => "medium",
        "retention_aid" => "Test retention aid"
      }

      struct = Processed.Question.from_map(original_map)
      converted_map = Processed.Question.to_map(struct)

      # Convert string keys to atom keys for comparison
      original_with_atom_keys = Map.new(original_map, fn {k, v} -> {String.to_atom(k), v} end)

      assert converted_map == original_with_atom_keys
    end

    test "TrueFalse survives map -> struct -> map conversion" do
      original_map = %{
        "question_type" => "true_false",
        "question_text" => "Test statement",
        "is_correct_true" => false,
        "explanation" => "Test explanation",
        "difficulty" => "easy",
        "retention_aid" => "Test retention aid"
      }

      struct = Processed.Question.from_map(original_map)
      converted_map = Processed.Question.to_map(struct)

      original_with_atom_keys = Map.new(original_map, fn {k, v} -> {String.to_atom(k), v} end)

      assert converted_map == original_with_atom_keys
    end

    test "Emq survives map -> struct -> map conversion" do
      original_map = %{
        "question_type" => "emq",
        "instructions" => "Match the following",
        "premises" => ["Item 1", "Item 2"],
        "options" => ["Option A", "Option B"],
        "matches" => [{0, 1}, {1, 0}],
        "explanation" => "Matching explanation",
        "difficulty" => "hard",
        "retention_aid" => "Test retention aid"
      }

      struct = Processed.Question.from_map(original_map)
      converted_map = Processed.Question.to_map(struct)

      original_with_atom_keys = Map.new(original_map, fn {k, v} -> {String.to_atom(k), v} end)

      assert converted_map == original_with_atom_keys
    end

    test "round-trip conversion with nil retention_aid" do
      original_map = %{
        "question_type" => "mcq_single",
        "question_text" => "Test question",
        "options" => ["A", "B", "C"],
        "correct_index" => 1,
        "explanation" => "Test explanation",
        "difficulty" => "medium"
        # No retention_aid provided, should be nil
      }

      struct = Processed.Question.from_map(original_map)
      converted_map = Processed.Question.to_map(struct)

      # Add retention_aid: nil to expected result
      expected_map = Map.new(original_map, fn {k, v} -> {String.to_atom(k), v} end)
      expected_map = Map.put(expected_map, :retention_aid, nil)

      assert converted_map == expected_map
    end
  end
end
