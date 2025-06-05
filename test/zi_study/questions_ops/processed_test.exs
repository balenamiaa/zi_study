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

  describe "Processed.Answer.from_map/1" do
    test "creates McqSingleAnswer struct from map" do
      map = %{
        "answer_type" => "mcq_single",
        "selected_index" => 2
      }

      result = Processed.Answer.from_map(map)

      assert %Processed.Answer.McqSingleAnswer{} = result
      assert result.selected_index == 2
      assert result.answer_type == "mcq_single"
    end

    test "creates McqMultiAnswer struct from map" do
      map = %{
        "answer_type" => "mcq_multi",
        "selected_indices" => [0, 2, 3]
      }

      result = Processed.Answer.from_map(map)

      assert %Processed.Answer.McqMultiAnswer{} = result
      assert result.selected_indices == [0, 2, 3]
      assert result.answer_type == "mcq_multi"
    end

    test "creates TrueFalseAnswer struct from map with is_true field" do
      map = %{
        "answer_type" => "true_false",
        "is_true" => true
      }

      result = Processed.Answer.from_map(map)

      assert %Processed.Answer.TrueFalseAnswer{} = result
      assert result.selected == true
      assert result.answer_type == "true_false"
    end

    test "creates TrueFalseAnswer struct from map with legacy selected field" do
      map = %{
        "answer_type" => "true_false",
        "selected" => false
      }

      result = Processed.Answer.from_map(map)

      assert %Processed.Answer.TrueFalseAnswer{} = result
      assert result.selected == false
      assert result.answer_type == "true_false"
    end

    test "creates WrittenAnswer struct from map with text field" do
      map = %{
        "answer_type" => "written",
        "text" => "This is my written response to the question."
      }

      result = Processed.Answer.from_map(map)

      assert %Processed.Answer.WrittenAnswer{} = result
      assert result.text == "This is my written response to the question."
      assert result.answer_type == "written"
    end

    test "creates WrittenAnswer struct from map with legacy answer_text field" do
      map = %{
        "answer_type" => "written",
        "answer_text" => "Legacy format written response."
      }

      result = Processed.Answer.from_map(map)

      assert %Processed.Answer.WrittenAnswer{} = result
      assert result.text == "Legacy format written response."
      assert result.answer_type == "written"
    end

    test "creates ClozeAnswer struct from map" do
      map = %{
        "answer_type" => "cloze",
        "answers" => ["Paris", "France", "Europe"]
      }

      result = Processed.Answer.from_map(map)

      assert %Processed.Answer.ClozeAnswer{} = result
      assert result.answers == ["Paris", "France", "Europe"]
      assert result.answer_type == "cloze"
    end

    test "creates EmqAnswer struct from map" do
      map = %{
        "answer_type" => "emq",
        "matches" => [[0, 1], [1, 0], [2, 2]]
      }

      result = Processed.Answer.from_map(map)

      assert %Processed.Answer.EmqAnswer{} = result
      assert result.matches == [[0, 1], [1, 0], [2, 2]]
      assert result.answer_type == "emq"
    end

    test "raises error for unknown answer type" do
      map = %{
        "answer_type" => "unknown_type",
        "some_field" => "some_value"
      }

      assert_raise RuntimeError, ~r/Unknown answer type/, fn ->
        Processed.Answer.from_map(map)
      end
    end

    test "raises error for missing answer_type" do
      map = %{
        "selected_index" => 1
      }

      assert_raise KeyError, fn ->
        Processed.Answer.from_map(map)
      end
    end

    test "raises error for MCQ single with missing selected_index" do
      map = %{
        "answer_type" => "mcq_single"
      }

      assert_raise ArgumentError, fn ->
        Processed.Answer.from_map(map)
      end
    end

    test "raises error for MCQ multi with missing selected_indices" do
      map = %{
        "answer_type" => "mcq_multi"
      }

      assert_raise ArgumentError, fn ->
        Processed.Answer.from_map(map)
      end
    end

    test "raises error for true/false with missing boolean field" do
      map = %{
        "answer_type" => "true_false"
      }

      assert_raise ArgumentError, fn ->
        Processed.Answer.from_map(map)
      end
    end

    test "raises error for written with missing text field" do
      map = %{
        "answer_type" => "written"
      }

      assert_raise ArgumentError, fn ->
        Processed.Answer.from_map(map)
      end
    end

    test "raises error for cloze with missing answers" do
      map = %{
        "answer_type" => "cloze"
      }

      assert_raise ArgumentError, fn ->
        Processed.Answer.from_map(map)
      end
    end

    test "raises error for EMQ with missing matches" do
      map = %{
        "answer_type" => "emq"
      }

      assert_raise ArgumentError, fn ->
        Processed.Answer.from_map(map)
      end
    end
  end

  describe "Processed.Answer.to_map/1" do
    test "converts McqSingleAnswer struct to map" do
      struct = %Processed.Answer.McqSingleAnswer{
        selected_index: 1
      }

      result = Processed.Answer.to_map(struct)

      expected = %{
        selected_index: 1,
        answer_type: "mcq_single"
      }

      assert result == expected
    end

    test "converts McqMultiAnswer struct to map" do
      struct = %Processed.Answer.McqMultiAnswer{
        selected_indices: [0, 1, 3]
      }

      result = Processed.Answer.to_map(struct)

      expected = %{
        selected_indices: [0, 1, 3],
        answer_type: "mcq_multi"
      }

      assert result == expected
    end

    test "converts TrueFalseAnswer struct to map" do
      struct = %Processed.Answer.TrueFalseAnswer{
        selected: true
      }

      result = Processed.Answer.to_map(struct)

      expected = %{
        selected: true,
        answer_type: "true_false"
      }

      assert result == expected
    end

    test "converts WrittenAnswer struct to map" do
      struct = %Processed.Answer.WrittenAnswer{
        text: "My detailed written response."
      }

      result = Processed.Answer.to_map(struct)

      expected = %{
        text: "My detailed written response.",
        answer_type: "written"
      }

      assert result == expected
    end

    test "converts ClozeAnswer struct to map" do
      struct = %Processed.Answer.ClozeAnswer{
        answers: ["word1", "word2", "word3"]
      }

      result = Processed.Answer.to_map(struct)

      expected = %{
        answers: ["word1", "word2", "word3"],
        answer_type: "cloze"
      }

      assert result == expected
    end

    test "converts EmqAnswer struct to map" do
      struct = %Processed.Answer.EmqAnswer{
        matches: [[0, 0], [1, 1], [2, 2]]
      }

      result = Processed.Answer.to_map(struct)

      expected = %{
        matches: [[0, 0], [1, 1], [2, 2]],
        answer_type: "emq"
      }

      assert result == expected
    end
  end

  describe "Answer round-trip conversion" do
    test "McqSingleAnswer survives map -> struct -> map conversion" do
      original_map = %{
        "answer_type" => "mcq_single",
        "selected_index" => 2
      }

      struct = Processed.Answer.from_map(original_map)
      converted_map = Processed.Answer.to_map(struct)

      # Convert string keys to atom keys for comparison
      original_with_atom_keys = Map.new(original_map, fn {k, v} -> {String.to_atom(k), v} end)

      assert converted_map == original_with_atom_keys
    end

    test "McqMultiAnswer survives map -> struct -> map conversion" do
      original_map = %{
        "answer_type" => "mcq_multi",
        "selected_indices" => [0, 2, 4]
      }

      struct = Processed.Answer.from_map(original_map)
      converted_map = Processed.Answer.to_map(struct)

      original_with_atom_keys = Map.new(original_map, fn {k, v} -> {String.to_atom(k), v} end)

      assert converted_map == original_with_atom_keys
    end

    test "TrueFalseAnswer with is_true survives conversion" do
      original_map = %{
        "answer_type" => "true_false",
        "is_true" => false
      }

      struct = Processed.Answer.from_map(original_map)
      converted_map = Processed.Answer.to_map(struct)

      # The conversion normalizes to 'selected' field
      expected_map = %{
        answer_type: "true_false",
        selected: false
      }

      assert converted_map == expected_map
    end

    test "TrueFalseAnswer with selected survives conversion" do
      original_map = %{
        "answer_type" => "true_false",
        "selected" => true
      }

      struct = Processed.Answer.from_map(original_map)
      converted_map = Processed.Answer.to_map(struct)

      original_with_atom_keys = Map.new(original_map, fn {k, v} -> {String.to_atom(k), v} end)

      assert converted_map == original_with_atom_keys
    end

    test "WrittenAnswer with text survives conversion" do
      original_map = %{
        "answer_type" => "written",
        "text" => "My written answer"
      }

      struct = Processed.Answer.from_map(original_map)
      converted_map = Processed.Answer.to_map(struct)

      original_with_atom_keys = Map.new(original_map, fn {k, v} -> {String.to_atom(k), v} end)

      assert converted_map == original_with_atom_keys
    end

    test "WrittenAnswer with answer_text survives conversion" do
      original_map = %{
        "answer_type" => "written",
        "answer_text" => "Legacy format answer"
      }

      struct = Processed.Answer.from_map(original_map)
      converted_map = Processed.Answer.to_map(struct)

      # The conversion normalizes to 'text' field
      expected_map = %{
        answer_type: "written",
        text: "Legacy format answer"
      }

      assert converted_map == expected_map
    end

    test "ClozeAnswer survives map -> struct -> map conversion" do
      original_map = %{
        "answer_type" => "cloze",
        "answers" => ["answer1", "answer2", "answer3"]
      }

      struct = Processed.Answer.from_map(original_map)
      converted_map = Processed.Answer.to_map(struct)

      original_with_atom_keys = Map.new(original_map, fn {k, v} -> {String.to_atom(k), v} end)

      assert converted_map == original_with_atom_keys
    end

    test "EmqAnswer survives map -> struct -> map conversion" do
      original_map = %{
        "answer_type" => "emq",
        "matches" => [[0, 1], [1, 2], [2, 0]]
      }

      struct = Processed.Answer.from_map(original_map)
      converted_map = Processed.Answer.to_map(struct)

      original_with_atom_keys = Map.new(original_map, fn {k, v} -> {String.to_atom(k), v} end)

      assert converted_map == original_with_atom_keys
    end
  end

  describe "Answer data validation" do
    test "McqSingleAnswer validates selected_index is non-negative integer" do
      # Valid cases
      valid_map = %{"answer_type" => "mcq_single", "selected_index" => 0}

      assert %Processed.Answer.McqSingleAnswer{selected_index: 0} =
               Processed.Answer.from_map(valid_map)

      valid_map2 = %{"answer_type" => "mcq_single", "selected_index" => 5}

      assert %Processed.Answer.McqSingleAnswer{selected_index: 5} =
               Processed.Answer.from_map(valid_map2)

      # Negative values are accepted at struct level, validation happens at question level
      negative_map = %{"answer_type" => "mcq_single", "selected_index" => -1}

      assert %Processed.Answer.McqSingleAnswer{selected_index: -1} =
               Processed.Answer.from_map(negative_map)
    end

    test "McqMultiAnswer validates selected_indices is list of non-negative integers" do
      # Valid cases
      valid_map = %{"answer_type" => "mcq_multi", "selected_indices" => []}

      assert %Processed.Answer.McqMultiAnswer{selected_indices: []} =
               Processed.Answer.from_map(valid_map)

      valid_map2 = %{"answer_type" => "mcq_multi", "selected_indices" => [0, 1, 2]}

      assert %Processed.Answer.McqMultiAnswer{selected_indices: [0, 1, 2]} =
               Processed.Answer.from_map(valid_map2)

      # Test with duplicate indices (should be preserved as-is)
      valid_map3 = %{"answer_type" => "mcq_multi", "selected_indices" => [0, 0, 1]}

      assert %Processed.Answer.McqMultiAnswer{selected_indices: [0, 0, 1]} =
               Processed.Answer.from_map(valid_map3)
    end

    test "ClozeAnswer validates answers is list of strings" do
      # Valid cases
      valid_map = %{"answer_type" => "cloze", "answers" => []}
      assert %Processed.Answer.ClozeAnswer{answers: []} = Processed.Answer.from_map(valid_map)

      valid_map2 = %{"answer_type" => "cloze", "answers" => ["answer1", "answer2"]}

      assert %Processed.Answer.ClozeAnswer{answers: ["answer1", "answer2"]} =
               Processed.Answer.from_map(valid_map2)

      # Test with empty strings (should be preserved)
      valid_map3 = %{"answer_type" => "cloze", "answers" => ["", "answer"]}

      assert %Processed.Answer.ClozeAnswer{answers: ["", "answer"]} =
               Processed.Answer.from_map(valid_map3)
    end

    test "EmqAnswer validates matches is list of tuples/lists" do
      # Valid cases with tuples
      valid_map = %{"answer_type" => "emq", "matches" => []}
      assert %Processed.Answer.EmqAnswer{matches: []} = Processed.Answer.from_map(valid_map)

      valid_map2 = %{"answer_type" => "emq", "matches" => [[0, 1], [1, 0]]}

      assert %Processed.Answer.EmqAnswer{matches: [[0, 1], [1, 0]]} =
               Processed.Answer.from_map(valid_map2)

      # Test with different formats
      valid_map3 = %{"answer_type" => "emq", "matches" => [{0, 1}, {1, 0}]}

      assert %Processed.Answer.EmqAnswer{matches: [{0, 1}, {1, 0}]} =
               Processed.Answer.from_map(valid_map3)
    end
  end
end
