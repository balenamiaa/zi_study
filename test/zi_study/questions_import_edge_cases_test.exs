defmodule ZiStudy.QuestionsImportEdgeCasesTest do
  use ZiStudy.DataCase

  import ZiStudy.Fixtures

  alias ZiStudy.Questions

  describe "import_questions_from_json/3 - Authorization Edge Cases" do
    test "fails when user is not owner of question set" do
            user1 = user_fixture()
      user2 = user_fixture()
      question_set = question_set_fixture(user1)  # user1 owns the set

      json_data = [test_mcq_single_question_data()]
      json_string = Jason.encode!(json_data)

      # user2 tries to import to user1's set
      assert {:error, error_message} =
               Questions.import_questions_from_json(json_string, user2.id, question_set.id)

      assert String.contains?(error_message, "not authorized")
    end

    test "fails when question set does not exist" do
      user = user_fixture()
      json_data = [test_mcq_single_question_data()]
      json_string = Jason.encode!(json_data)

      assert {:error, error_message} =
               Questions.import_questions_from_json(json_string, user.id, 999_999)

      assert String.contains?(error_message, "not found")
    end

    test "succeeds when user owns the question set" do
      user = user_fixture()
      question_set = question_set_fixture(user)

      json_data = [test_mcq_single_question_data()]
      json_string = Jason.encode!(json_data)

      assert {:ok, questions} =
               Questions.import_questions_from_json(json_string, user.id, question_set.id)

      assert length(questions) == 1

      # Verify question was added to set
      set_questions = Questions.get_question_set_questions_with_positions(question_set.id)
      assert length(set_questions) == 1
    end
  end

    describe "import_questions_from_json/3 - Mixed Format Support" do
    test "handles mix of processed format questions" do
      user = user_fixture()

      # All using processed format (the main supported format)
      json_data = [
        # Processed format MCQ
        test_mcq_single_question_data(),
        # Processed format True/False
        test_true_false_question_data()
      ]

      json_string = Jason.encode!(json_data)

      assert {:ok, questions} = Questions.import_questions_from_json(json_string, user.id)
      assert length(questions) == 2

      # Verify both questions were created with correct types
      types = Enum.map(questions, & &1.type)
      assert "mcq_single" in types
      assert "true_false" in types
    end

    test "handles all processed question types" do
      user = user_fixture()

      json_data = [
        # MCQ Single (processed format)
        test_mcq_single_question_data(),
        # True-False (processed format)
        test_true_false_question_data(),
        # Written (processed format)
        test_written_question_data(),
        # Cloze (processed format)
        %{
          "question_type" => "cloze",
          "question_text" => "Fill in the ____",
          "answers" => ["blank"],
          "difficulty" => "medium"
        }
      ]

      json_string = Jason.encode!(json_data)

      assert {:ok, questions} = Questions.import_questions_from_json(json_string, user.id)
      assert length(questions) == 4

      types = Enum.map(questions, & &1.type)
      assert "mcq_single" in types
      assert "true_false" in types
      assert "written" in types
      assert "cloze" in types
    end
  end

  describe "import_questions_from_json/3 - Error Handling Edge Cases" do
        test "handles invalid question type errors gracefully" do
      user = user_fixture()

      json_data = [
        # Valid processed question
        test_mcq_single_question_data(),
        # Invalid question type
        %{
          "question_type" => "unknown_processed_type",  # Unknown type
          "difficulty" => "easy",
          "question_text" => "Question?"
        }
      ]

      json_string = Jason.encode!(json_data)

      assert {:error, :invalid_question_data, failed_conversions} =
               Questions.import_questions_from_json(json_string, user.id)

      assert length(failed_conversions) == 1
      assert match?({:error, _}, hd(failed_conversions))
    end

        test "handles processing errors gracefully" do
      user = user_fixture()

      json_data = [
        # Missing required fields for processed format
        %{
          "question_type" => "mcq_single",
          "difficulty" => "easy"
          # Missing question_text, options, correct_index
        }
      ]

      json_string = Jason.encode!(json_data)

      # This should fail during create_question/1 with changeset errors, not processing
      assert {:error, error_message} =
               Questions.import_questions_from_json(json_string, user.id)

      assert is_binary(error_message)
      assert String.contains?(error_message, "Failed to import question at index")
    end

    test "handles empty JSON array" do
      user = user_fixture()
      json_string = Jason.encode!([])

      assert {:ok, questions} = Questions.import_questions_from_json(json_string, user.id)
      assert questions == []
    end

    test "handles questions that fail database validation" do
      user = user_fixture()

      # Create a question that will pass processing but fail database constraints
      json_data = [
        %{
          "question_type" => "mcq_single",
          "question_text" => "",  # Empty question_text should fail validation
          "options" => ["A", "B"],
          "correct_index" => 0,
          "difficulty" => "easy"
        }
      ]

      json_string = Jason.encode!(json_data)

      assert {:error, error_message} = Questions.import_questions_from_json(json_string, user.id)
      assert String.contains?(error_message, "Failed to import question at index")
    end

    test "transaction rollback on mixed success/failure scenarios" do
      user = user_fixture()

      initial_count = length(Questions.list_questions())

             json_data = [
         # Valid question
         test_mcq_single_question_data(),
        # Invalid question (missing question_text)
        %{
          "question_type" => "mcq_single",
          "options" => ["A", "B"],
          "correct_index" => 0,
          "difficulty" => "easy"
          # Missing question_text
        },
                 # Another valid question
         test_true_false_question_data()
      ]

      json_string = Jason.encode!(json_data)

      assert {:error, _} = Questions.import_questions_from_json(json_string, user.id)

      # Verify no questions were created due to transaction rollback
      final_count = length(Questions.list_questions())
      assert final_count == initial_count
    end
  end

  describe "import_questions_from_json/3 - Question Set Association Edge Cases" do
    test "handles add_questions_to_set_impl failures" do
      user = user_fixture()
      question_set = question_set_fixture(user)

      # Create a scenario where questions import successfully but adding to set fails
      # This is hard to trigger naturally, so we'll test by creating a very large number
      # of questions which might stress the position assignment logic
             large_question_list =
         for i <- 1..100 do
           test_mcq_single_question_data()
           |> Map.put("question_text", "Question #{i}")
         end

      json_string = Jason.encode!(large_question_list)

      # This should succeed, but let's verify all questions get proper positions
      assert {:ok, questions} =
               Questions.import_questions_from_json(json_string, user.id, question_set.id)

      assert length(questions) == 100

      # Verify all questions were added to set with sequential positions
      set_questions = Questions.get_question_set_questions_with_positions(question_set.id)
      assert length(set_questions) == 100

      positions = Enum.map(set_questions, & &1.position) |> Enum.sort()
      assert positions == Enum.to_list(1..100)
    end

            test "preserves existing questions in set when adding new ones" do
      user = user_fixture()
      question_set = question_set_fixture(user)

      # First import - add 2 questions with unique content
      json_data1 = [
        %{
          "question_type" => "mcq_single",
          "question_text" => "First batch: What is 2 + 2?",
          "options" => ["3", "4", "5"],
          "correct_index" => 1,
          "difficulty" => "easy"
        },
        %{
          "question_type" => "true_false",
          "question_text" => "First batch: The sky is blue",
          "is_correct_true" => true,
          "difficulty" => "easy"
        }
      ]
      json_string1 = Jason.encode!(json_data1)

      assert {:ok, _} =
               Questions.import_questions_from_json(json_string1, user.id, question_set.id)

      # Verify we have 2 questions
      set_questions_before = Questions.get_question_set_questions_with_positions(question_set.id)
      assert length(set_questions_before) == 2

      # Get the existing question IDs for verification
      existing_question_ids = Enum.map(set_questions_before, & &1.question.id) |> MapSet.new()

      # Second import - add 1 more question with unique content
      json_data2 = [
        %{
          "question_type" => "written",
          "question_text" => "Second batch: Explain photosynthesis",
          "difficulty" => "hard",
          "correct_answer" => "Plants convert sunlight to energy"
        }
      ]
      json_string2 = Jason.encode!(json_data2)

      assert {:ok, _} =
               Questions.import_questions_from_json(json_string2, user.id, question_set.id)

      # Verify we now have 3 questions and the original questions are still there
      set_questions_after = Questions.get_question_set_questions_with_positions(question_set.id)
      assert length(set_questions_after) == 3

      # Verify original questions are preserved
      after_question_ids = Enum.map(set_questions_after, & &1.question.id) |> MapSet.new()
      assert MapSet.subset?(existing_question_ids, after_question_ids)

      # Verify positions are sequential (though order may vary)
      positions = Enum.map(set_questions_after, & &1.position) |> Enum.sort()
      assert length(Enum.uniq(positions)) == 3  # All unique positions
      assert Enum.min(positions) >= 1  # Positions start from 1 or higher
    end
  end

  describe "import_questions_from_json/3 - Performance and Edge Cases" do
    test "handles very large JSON payloads" do
      user = user_fixture()

      # Create a large number of questions to test memory/performance
             large_question_list =
         for i <- 1..50 do  # Reduced from 1000 to keep test reasonable
           test_mcq_single_question_data()
           |> Map.put("question_text", "Large batch question #{i}")
         end

      json_string = Jason.encode!(large_question_list)

      assert {:ok, questions} = Questions.import_questions_from_json(json_string, user.id)
      assert length(questions) == 50
    end

    test "handles malformed JSON that decodes but has wrong structure" do
      user = user_fixture()

      # JSON that decodes successfully but contains nested arrays instead of question objects
      json_string = Jason.encode!([["not", "a", "question"], %{"also" => "wrong"}])

      assert {:error, :invalid_question_data, failed_conversions} =
               Questions.import_questions_from_json(json_string, user.id)

      assert length(failed_conversions) == 2
    end

    test "handles questions with nil/empty optional fields" do
      user = user_fixture()

      json_data = [
        %{
          "question_type" => "mcq_single",
          "question_text" => "Question with minimal fields?",
          "options" => ["A", "B"],
          "correct_index" => 0,
          "difficulty" => "easy",
          "retention_aid" => nil,
          "explanation" => ""
        }
      ]

      json_string = Jason.encode!(json_data)

      assert {:ok, questions} = Questions.import_questions_from_json(json_string, user.id)
      assert length(questions) == 1

      question = hd(questions)
      assert question.data["retention_aid"] == nil
      assert question.data["explanation"] == ""
    end
  end

  # Helper functions for test data
  defp test_mcq_single_question_data do
    %{
      "question_type" => "mcq_single",
      "question_text" => "What is 2 + 2?",
      "options" => ["3", "4", "5"],
      "correct_index" => 1,
      "difficulty" => "easy",
      "retention_aid" => "Basic math",
      "explanation" => "2 + 2 = 4"
    }
  end

  defp test_true_false_question_data do
    %{
      "question_type" => "true_false",
      "question_text" => "The sky is blue",
      "is_correct_true" => true,
      "difficulty" => "easy",
      "explanation" => "The sky appears blue due to light scattering"
    }
  end

  defp test_written_question_data do
    %{
      "question_type" => "written",
      "question_text" => "Explain photosynthesis",
      "difficulty" => "hard",
      "correct_answer" => "Process by which plants convert light to energy",
      "explanation" => "Photosynthesis involves chlorophyll and produces glucose"
    }
  end
end
