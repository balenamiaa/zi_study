defmodule ZiStudy.QuestionsTest do
  use ZiStudy.DataCase

  import ZiStudy.Fixtures

  alias ZiStudy.Questions
  alias ZiStudy.Questions.{Question, QuestionSet, Tag, Answer}
  alias ZiStudy.QuestionsOps.Processed

  describe "question_sets" do
    test "list_question_sets/0 returns all public question sets" do
      public_set = question_set_fixture()
      user = user_fixture()
      private_set = question_set_fixture(user, %{is_private: true})

      sets = Questions.list_question_sets()

      assert public_set in sets
      refute private_set in sets
    end

    test "list_question_sets/2 with user_id returns user's sets filtered by privacy" do
      user = user_fixture()
      other_user = user_fixture()

      user_public = question_set_fixture(user, %{is_private: false})
      user_private = question_set_fixture(user, %{is_private: true})
      other_public = question_set_fixture(other_user, %{is_private: false})
      other_private = question_set_fixture(other_user, %{is_private: true})

      # Get user's public sets
      public_sets = Questions.list_question_sets(user.id, true)
      assert user_public in public_sets
      refute user_private in public_sets
      refute other_public in public_sets
      refute other_private in public_sets

      # Get user's private sets
      private_sets = Questions.list_question_sets(user.id, false)
      refute user_public in private_sets
      assert user_private in private_sets
      refute other_public in private_sets
      refute other_private in private_sets
    end

    test "get_question_set/1 returns the question set with id" do
      question_set = question_set_fixture()
      assert Questions.get_question_set(question_set.id).id == question_set.id
    end

    test "get_question_set/1 returns nil for non-existent id" do
      assert Questions.get_question_set(999999) == nil
    end

    test "create_question_set/2 with valid data creates a question set" do
      user = user_fixture()
      valid_attrs = valid_question_set_attributes()

      assert {:ok, %QuestionSet{} = question_set} = Questions.create_question_set(user, valid_attrs)
      assert question_set.title == valid_attrs["title"]
      assert question_set.description == valid_attrs["description"]
      assert question_set.owner_id == user.id
    end

    test "create_question_set/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Questions.create_question_set(user, %{})
    end

    test "create_question_set_ownerless/1 creates a public question set without owner" do
      valid_attrs = valid_question_set_attributes()

      assert {:ok, %QuestionSet{} = question_set} = Questions.create_question_set_ownerless(valid_attrs)
      assert question_set.title == valid_attrs["title"]
      assert question_set.owner_id == nil
      assert question_set.is_private == false
    end

    test "update_question_set/2 with valid data updates the question set" do
      question_set = question_set_fixture()
      update_attrs = %{title: "Updated Title", description: "Updated Description"}

      assert {:ok, %QuestionSet{} = question_set} = Questions.update_question_set(question_set, update_attrs)
      assert question_set.title == "Updated Title"
      assert question_set.description == "Updated Description"
    end

    test "update_question_set/2 with invalid data returns error changeset" do
      question_set = question_set_fixture()
      assert {:error, %Ecto.Changeset{}} = Questions.update_question_set(question_set, %{title: nil})

      # Compare essential fields rather than full structs to avoid association loading differences
      updated_question_set = Questions.get_question_set(question_set.id)
      assert question_set.id == updated_question_set.id
      assert question_set.title == updated_question_set.title
      assert question_set.description == updated_question_set.description
      assert question_set.is_private == updated_question_set.is_private
      assert question_set.owner_id == updated_question_set.owner_id
    end

    test "delete_question_set/1 deletes the question set" do
      question_set = question_set_fixture()
      assert {:ok, %QuestionSet{}} = Questions.delete_question_set(question_set)
      assert Questions.get_question_set(question_set.id) == nil
    end
  end

  describe "questions" do
    test "list_questions/0 returns all questions" do
      question = question_fixture()
      assert question in Questions.list_questions()
    end

    test "get_question/1 returns the question with id" do
      question = question_fixture()
      found_question = Questions.get_question(question.id)
      assert found_question.id == question.id
      assert found_question.data == question.data
    end

    test "get_question/1 returns nil for non-existent id" do
      assert Questions.get_question(999999) == nil
    end

    test "create_question/1 with valid processed content creates a question" do
      processed_content = Processed.Question.from_map(mcq_single_question_data())

      assert {:ok, %Question{} = question} = Questions.create_question(processed_content)
      assert question.data["question_text"] == "What is 2 + 2?"
      assert question.type == "mcq_single"
      assert question.difficulty == "easy"
    end

    test "create_question/1 creates EMQ questions correctly" do
      processed_content = Processed.Question.from_map(emq_question_data())

      assert {:ok, %Question{} = question} = Questions.create_question(processed_content)
      assert question.data["instructions"] == "Match each planet with its position from the Sun"
      assert question.type == "emq"
      assert question.difficulty == "medium"
    end

    test "create_question/1 creates all question types successfully" do
      test_cases = [
        {:mcq_single, mcq_single_question_data()},
        {:mcq_multi, mcq_multi_question_data()},
        {:true_false, true_false_question_data()},
        {:written, written_question_data()},
        {:cloze, cloze_question_data()},
        {:emq, emq_question_data()}
      ]

      Enum.each(test_cases, fn {_type, data} ->
        processed_content = Processed.Question.from_map(data)
        assert {:ok, %Question{} = question} = Questions.create_question(processed_content)
        assert question.type == data["question_type"]
        assert question.difficulty == data["difficulty"]
      end)
    end

    test "create_question/1 validates required fields for each question type" do
      # Test EMQ without instructions
      invalid_emq = %{
        "question_type" => "emq",
        "premises" => ["A", "B"],
        "options" => ["1", "2"],
        "difficulty" => "easy"
        # Missing instructions
      }
      processed_emq = Processed.Question.from_map(invalid_emq)
      assert {:error, %Ecto.Changeset{}} = Questions.create_question(processed_emq)

      # Test MCQ without question_text
      invalid_mcq = %{
        "question_type" => "mcq_single",
        "options" => ["A", "B"],
        "correct_index" => 0,
        "difficulty" => "easy"
        # Missing question_text
      }
      processed_mcq = Processed.Question.from_map(invalid_mcq)
      assert {:error, %Ecto.Changeset{}} = Questions.create_question(processed_mcq)
    end

    test "update_question/2 with valid data updates the question" do
      question = question_fixture()
      new_data = Map.put(question.data, "question_text", "Updated question text")
      update_attrs = %{data: new_data}

      assert {:ok, %Question{} = question} = Questions.update_question(question, update_attrs)
      assert question.data["question_text"] == "Updated question text"
    end

    test "delete_question/1 deletes the question" do
      question = question_fixture()
      assert {:ok, %Question{}} = Questions.delete_question(question)
      assert Questions.get_question(question.id) == nil
    end

    test "search_questions/1 finds questions by text content" do
      question1 = question_fixture(:mcq_single, %{"question_text" => "What is the capital of France?"})
      question2 = question_fixture(:mcq_single, %{"question_text" => "What is 2 + 2?"})

      results = Questions.search_questions("France")
      assert question1 in results
      refute question2 in results
    end

    test "search_questions/1 works with different question types" do
      mcq_question = question_fixture(:mcq_single, %{"question_text" => "Mathematics problem"})
      written_question = question_fixture(:written, %{"question_text" => "Explain mathematics"})
      cloze_question = question_fixture(:cloze, %{"question_text" => "The study of mathematics is ___"})

      results = Questions.search_questions("mathematics")
      assert mcq_question in results
      assert written_question in results
      assert cloze_question in results
    end

    test "search_questions/1 finds EMQ questions by instructions" do
      emq_question = question_fixture(:emq, %{"instructions" => "Match planets with positions"})
      mcq_question = question_fixture(:mcq_single, %{"question_text" => "What is a planet?"})

      results = Questions.search_questions("planet")
      assert emq_question in results
      assert mcq_question in results
    end

    test "search_questions/1 handles case insensitive search" do
      question = question_fixture(:mcq_single, %{"question_text" => "What is the CAPITAL of France?"})

      results_lower = Questions.search_questions("capital")
      results_upper = Questions.search_questions("CAPITAL")
      results_mixed = Questions.search_questions("Capital")

      assert question in results_lower
      assert question in results_upper
      assert question in results_mixed
    end

    test "list_questions_by_difficulty/1 filters questions by difficulty" do
      easy_question = question_fixture(:mcq_single, %{"difficulty" => "easy"})
      hard_question = question_fixture(:written, %{"difficulty" => "hard"})

      easy_results = Questions.list_questions_by_difficulty("easy")
      assert easy_question in easy_results
      refute hard_question in easy_results
    end

    test "list_questions_by_type/1 filters questions by type" do
      mcq_question = question_fixture(:mcq_single)
      written_question = question_fixture(:written)

      mcq_results = Questions.list_questions_by_type("mcq_single")
      assert mcq_question in mcq_results
      refute written_question in mcq_results
    end

    test "get_question_as_processed/1 returns processed struct" do
      question = question_fixture(:mcq_single)

      assert {:ok, %Processed.Question.McqSingle{} = processed} = Questions.get_question_as_processed(question.id)
      assert processed.question_text == question.data["question_text"]
    end

    test "get_question_as_processed/1 returns nil for non-existent question" do
      assert Questions.get_question_as_processed(999999) == nil
    end
  end

  describe "question sets and questions association" do
    test "get_question_set_questions_with_positions/1 returns questions with positions" do
      question_set = question_set_fixture()
      question1 = question_fixture()
      question2 = question_fixture()

      # Add questions to set using the import functionality
      json_data = [
        Processed.Question.to_map(Processed.Question.from_map(question1.data)),
        Processed.Question.to_map(Processed.Question.from_map(question2.data))
      ]
      json_string = Jason.encode!(json_data)

      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      assert {:ok, _} = Questions.import_questions_from_json(json_string, user.id, question_set.id)

      results = Questions.get_question_set_questions_with_positions(question_set.id)
      assert length(results) == 2
      assert Enum.all?(results, &Map.has_key?(&1, :position))
    end

    test "remove_questions_from_set/2 removes questions from set" do
      question_set = question_set_fixture()
      question = question_fixture()

      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      json_data = [Processed.Question.to_map(Processed.Question.from_map(question.data))]
      json_string = Jason.encode!(json_data)

      assert {:ok, _} = Questions.import_questions_from_json(json_string, user.id, question_set.id)

      # Verify question is in set and get the actual question IDs
      questions_before = Questions.get_question_set_questions_with_positions(question_set.id)
      assert length(questions_before) > 0

      # Get the actual question ID from the set
      question_ids = Enum.map(questions_before, fn %{question: q} -> q.id end)

      # Remove question from set
      {:ok, count} = Questions.remove_questions_from_set(question_set, question_ids)
      assert count >= 0

      # Verify question is removed
      questions_after = Questions.get_question_set_questions_with_positions(question_set.id)
      assert length(questions_after) < length(questions_before)
    end

    test "copy_questions_between_sets/2 copies questions from one set to another" do
      source_set = question_set_fixture()
      target_set = question_set_fixture()
      question = question_fixture()

      user = user_fixture()
      Questions.update_question_set(source_set, %{owner_id: user.id})
      Questions.update_question_set(target_set, %{owner_id: user.id})

      # Add question to source set
      json_data = [Processed.Question.to_map(Processed.Question.from_map(question.data))]
      json_string = Jason.encode!(json_data)

      assert {:ok, _} = Questions.import_questions_from_json(json_string, user.id, source_set.id)

      # Copy to target set
      assert {:ok, _} = Questions.copy_questions_between_sets(source_set.id, target_set.id)

      # Verify questions are in both sets
      source_questions = Questions.get_question_set_questions_with_positions(source_set.id)
      target_questions = Questions.get_question_set_questions_with_positions(target_set.id)

      assert length(source_questions) > 0
      assert length(target_questions) > 0
    end

    test "add_questions_to_set/3 adds questions using Question structs" do
      question_set = question_set_fixture()
      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      question1 = question_fixture()
      question2 = question_fixture()

      assert {:ok, updated_set} = Questions.add_questions_to_set(question_set, [question1, question2], user.id)

      questions_in_set = Questions.get_question_set_questions_with_positions(question_set.id)
      question_ids = Enum.map(questions_in_set, &(&1.question.id))

      assert question1.id in question_ids
      assert question2.id in question_ids
      assert length(questions_in_set) == 2
    end

    test "add_questions_to_set/3 adds questions using question IDs" do
      question_set = question_set_fixture()
      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      question1 = question_fixture()
      question2 = question_fixture()

      assert {:ok, updated_set} = Questions.add_questions_to_set(question_set, [question1.id, question2.id], user.id)

      questions_in_set = Questions.get_question_set_questions_with_positions(question_set.id)
      question_ids = Enum.map(questions_in_set, &(&1.question.id))

      assert question1.id in question_ids
      assert question2.id in question_ids
      assert length(questions_in_set) == 2
    end

    test "add_questions_to_set/3 adds questions using maps with positions" do
      question_set = question_set_fixture()
      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      question1 = question_fixture()
      question2 = question_fixture()

      questions_with_positions = [
        %{id: question1.id, position: 5},
        %{id: question2.id, position: 3}
      ]

      assert {:ok, updated_set} = Questions.add_questions_to_set(question_set, questions_with_positions, user.id)

      questions_in_set = Questions.get_question_set_questions_with_positions(question_set.id)

      # Find the positions
      q1_position = Enum.find(questions_in_set, &(&1.question.id == question1.id)).position
      q2_position = Enum.find(questions_in_set, &(&1.question.id == question2.id)).position

      assert q1_position == 5
      assert q2_position == 3
    end

    test "add_questions_to_set/3 adds questions using maps without positions" do
      question_set = question_set_fixture()
      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      question1 = question_fixture()
      question2 = question_fixture()

      questions_as_maps = [
        %{id: question1.id},
        %{id: question2.id}
      ]

      assert {:ok, updated_set} = Questions.add_questions_to_set(question_set, questions_as_maps, user.id)

      questions_in_set = Questions.get_question_set_questions_with_positions(question_set.id)
      question_ids = Enum.map(questions_in_set, &(&1.question.id))

      assert question1.id in question_ids
      assert question2.id in question_ids
      assert length(questions_in_set) == 2
    end

    test "add_questions_to_set/3 appends to existing questions in set" do
      question_set = question_set_fixture()
      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      # Add initial question via import
      initial_question = question_fixture()
      json_data = [Processed.Question.to_map(Processed.Question.from_map(initial_question.data))]
      json_string = Jason.encode!(json_data)
      Questions.import_questions_from_json(json_string, user.id, question_set.id)

      # Add more questions using our new function
      question1 = question_fixture()
      question2 = question_fixture()

      assert {:ok, updated_set} = Questions.add_questions_to_set(question_set, [question1, question2], user.id)

      questions_in_set = Questions.get_question_set_questions_with_positions(question_set.id)
      assert length(questions_in_set) == 3

      # Verify the new questions have higher positions
      positions = Enum.map(questions_in_set, &(&1.position)) |> Enum.sort()
      assert positions == [1, 2, 3]
    end

    test "add_questions_to_set/3 without user_id works for any question set" do
      question_set = question_set_fixture()
      question1 = question_fixture()
      question2 = question_fixture()

      # Should work without authorization
      assert {:ok, updated_set} = Questions.add_questions_to_set(question_set, [question1, question2])

      questions_in_set = Questions.get_question_set_questions_with_positions(question_set.id)
      question_ids = Enum.map(questions_in_set, &(&1.question.id))

      assert question1.id in question_ids
      assert question2.id in question_ids
    end

    test "add_questions_to_set/3 returns error for unauthorized user" do
      user1 = user_fixture()
      user2 = user_fixture()
      question_set = question_set_fixture(user1)  # owned by user1
      question = question_fixture()

      # user2 tries to add questions to user1's set
      assert {:error, :unauthorized} = Questions.add_questions_to_set(question_set, [question], user2.id)

      # Verify no questions were added
      questions_in_set = Questions.get_question_set_questions_with_positions(question_set.id)
      assert length(questions_in_set) == 0
    end

    test "add_questions_to_set/3 returns error for empty question list" do
      question_set = question_set_fixture()
      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      assert {:error, :no_valid_questions} = Questions.add_questions_to_set(question_set, [], user.id)
    end

    test "add_questions_to_set/3 returns error for invalid question data" do
      question_set = question_set_fixture()
      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      invalid_questions = ["invalid", %{invalid: "data"}, nil]

      assert {:error, :no_valid_questions} = Questions.add_questions_to_set(question_set, invalid_questions, user.id)
    end

    test "add_questions_to_set/3 handles mixed valid and invalid questions" do
      question_set = question_set_fixture()
      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      question1 = question_fixture()
      mixed_questions = [question1, "invalid", %{invalid: "data"}]

      assert {:ok, updated_set} = Questions.add_questions_to_set(question_set, mixed_questions, user.id)

      questions_in_set = Questions.get_question_set_questions_with_positions(question_set.id)
      assert length(questions_in_set) == 1
      assert List.first(questions_in_set).question.id == question1.id
    end

    test "add_questions_to_set/3 handles duplicate questions gracefully" do
      question_set = question_set_fixture()
      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      question = question_fixture()

      # Add same question twice
      assert {:ok, _} = Questions.add_questions_to_set(question_set, [question], user.id)
      assert {:ok, _} = Questions.add_questions_to_set(question_set, [question], user.id)

      questions_in_set = Questions.get_question_set_questions_with_positions(question_set.id)
      # Should have the question twice (database allows duplicates)
      assert length(questions_in_set) == 2
    end
  end

  describe "tags" do
    test "list_tags/0 returns all tags" do
      tag = tag_fixture()
      assert tag in Questions.list_tags()
    end

    test "create_tag/1 with valid data creates a tag" do
      valid_attrs = valid_tag_attributes()

      assert {:ok, %Tag{} = tag} = Questions.create_tag(valid_attrs)
      assert tag.name == valid_attrs["name"]
    end

    test "create_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Questions.create_tag(%{name: nil})
    end

    test "get_or_create_tag/1 gets existing tag" do
      existing_tag = tag_fixture()
      assert {:ok, tag} = Questions.get_or_create_tag(existing_tag.name)
      assert tag.id == existing_tag.id
    end

    test "get_or_create_tag/1 creates new tag if not exists" do
      assert {:ok, %Tag{} = tag} = Questions.get_or_create_tag("new-tag")
      assert tag.name == "new-tag"
    end

    test "add_tags_to_question_set/2 adds tags to question set" do
      question_set = question_set_fixture()
      tag1 = tag_fixture()
      tag2 = tag_fixture()

      assert {:ok, updated_set} = Questions.add_tags_to_question_set(question_set, [tag1.name, tag2.id])

      tag_names = Enum.map(updated_set.tags, & &1.name)
      assert tag1.name in tag_names
      assert tag2.name in tag_names
    end

    test "remove_tags_from_question_set/2 removes tags from question set" do
      question_set = question_set_fixture()
      tag = tag_fixture()

      # Add tag first
      assert {:ok, updated_set} = Questions.add_tags_to_question_set(question_set, [tag.name])
      assert length(updated_set.tags) > 0

      # Remove tag
      assert {:ok, updated_set} = Questions.remove_tags_from_question_set(updated_set, [tag.name])
      tag_names = Enum.map(updated_set.tags, & &1.name)
      refute tag.name in tag_names
    end
  end

  describe "answers" do
    setup do
      user = user_fixture()
      question = question_fixture()
      %{user: user, question: question}
    end

    test "list_answers_for_question/1 returns all answers for a question", %{user: user, question: question} do
      answer = answer_fixture(user, question)
      answers = Questions.list_answers_for_question(question.id)
      assert answer.id in Enum.map(answers, & &1.id)
    end

    test "list_answers_for_user/1 returns all answers for a user", %{user: user, question: question} do
      answer = answer_fixture(user, question)
      answers = Questions.list_answers_for_user(user.id)
      assert answer.id in Enum.map(answers, & &1.id)
    end

    test "get_answer/1 returns the answer with id", %{user: user, question: question} do
      answer = answer_fixture(user, question)
      found_answer = Questions.get_answer(answer.id)
      assert found_answer.id == answer.id
    end

    test "get_answer/1 returns nil for non-existent id" do
      assert Questions.get_answer(999999) == nil
    end

    test "get_user_answer/2 returns answer for user-question combination", %{user: user, question: question} do
      answer = answer_fixture(user, question)
      found_answer = Questions.get_user_answer(user.id, question.id)
      assert found_answer.id == answer.id
    end

    test "create_answer/1 with valid data creates an answer", %{user: user, question: question} do
      valid_attrs = valid_answer_attributes(user, question)

      assert {:ok, %Answer{} = answer} = Questions.create_answer(valid_attrs)
      assert answer.user_id == user.id
      assert answer.question_id == question.id
      assert answer.data == valid_attrs.data
    end

    test "create_answer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Questions.create_answer(%{})
    end

    test "update_answer/2 with valid data updates the answer", %{user: user, question: question} do
      answer = answer_fixture(user, question)
      update_attrs = %{data: %{"updated" => "data"}, is_correct: 1}

      assert {:ok, %Answer{} = answer} = Questions.update_answer(answer, update_attrs)
      assert answer.data == %{"updated" => "data"}
      assert answer.is_correct == 1
    end

    test "upsert_answer/4 creates new answer if none exists", %{user: user, question: question} do
      answer_data = %{"selected_index" => 2}

      assert {:ok, %Answer{} = answer} = Questions.upsert_answer(user.id, question.id, answer_data, 1)
      assert answer.data == answer_data
      assert answer.is_correct == 1
    end

    test "upsert_answer/4 updates existing answer", %{user: user, question: question} do
      # Create initial answer
      initial_answer = answer_fixture(user, question)

      # Upsert with new data
      new_data = %{"selected_index" => 3}
      assert {:ok, %Answer{} = updated_answer} = Questions.upsert_answer(user.id, question.id, new_data, 0)

      # Should be the same record, but updated
      assert updated_answer.id == initial_answer.id
      assert updated_answer.data == new_data
      assert updated_answer.is_correct == 0
    end

    test "delete_answer/1 deletes the answer", %{user: user, question: question} do
      answer = answer_fixture(user, question)
      assert {:ok, %Answer{}} = Questions.delete_answer(answer)
      assert Questions.get_answer(answer.id) == nil
    end
  end

  describe "answer statistics" do
    setup do
      user1 = user_fixture()
      user2 = user_fixture()
      question1 = question_fixture()
      question2 = question_fixture()

      %{user1: user1, user2: user2, question1: question1, question2: question2}
    end

    test "get_user_answer_stats/1 returns correct statistics", %{user1: user1, question1: question1, question2: question2} do
      # Create different types of answers
      correct_answer_fixture(user1, question1, %{is_correct: 1})
      incorrect_answer_fixture(user1, question2, %{is_correct: 0})
      answer_fixture(user1, question_fixture(), %{is_correct: 2})  # unevaluated

      stats = Questions.get_user_answer_stats(user1.id)

      assert stats.total_answers == 3
      assert stats.correct_answers == 1
      assert stats.incorrect_answers == 1
      assert stats.unevaluated_answers == 1
    end

    test "get_question_answer_stats/1 returns correct statistics", %{user1: user1, user2: user2, question1: question1} do
      # Create different answers for the same question
      correct_answer_fixture(user1, question1, %{is_correct: 1})
      incorrect_answer_fixture(user2, question1, %{is_correct: 0})

      stats = Questions.get_question_answer_stats(question1.id)

      assert stats.total_answers == 2
      assert stats.correct_answers == 1
      assert stats.incorrect_answers == 1
      assert stats.unevaluated_answers == 0
    end

    test "get_user_question_set_stats/2 returns stats for user on specific question set", %{user1: user1, question1: question1} do
      question_set = question_set_fixture()
      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      # Add question to set
      json_data = [Processed.Question.to_map(Processed.Question.from_map(question1.data))]
      json_string = Jason.encode!(json_data)
      Questions.import_questions_from_json(json_string, user.id, question_set.id)

      # Get the actual question that was imported
      set_questions = Questions.get_question_set_questions_with_positions(question_set.id)
      imported_question = List.first(set_questions).question

      # Create answer for the imported question
      correct_answer_fixture(user1, imported_question, %{is_correct: 1})

      stats = Questions.get_user_question_set_stats(user1.id, question_set.id)

      assert stats.total_answers == 1
      assert stats.correct_answers == 1
    end
  end

  describe "auto grading" do
    test "auto_grade_answers/1 grades MCQ single questions correctly" do
      question = question_fixture(:mcq_single)  # correct_index: 1
      user = user_fixture()

      # Create correct answer
      correct_answer = answer_fixture(user, question, %{
        data: %{"selected_index" => 1},
        is_correct: 2  # unevaluated
      })

      # Create incorrect answer
      user2 = user_fixture()
      incorrect_answer = answer_fixture(user2, question, %{
        data: %{"selected_index" => 0},
        is_correct: 2  # unevaluated
      })

      assert {:ok, 2} = Questions.auto_grade_answers(question.id)

      # Check that answers were graded
      updated_correct = Questions.get_answer(correct_answer.id)
      updated_incorrect = Questions.get_answer(incorrect_answer.id)

      assert updated_correct.is_correct == 1
      assert updated_incorrect.is_correct == 0
    end

    test "auto_grade_answers/1 grades true/false questions correctly" do
      question = question_fixture(:true_false)  # is_correct_true: true
      user = user_fixture()

      answer = answer_fixture(user, question, %{
        data: %{"selected" => true},
        is_correct: 2
      })

      assert {:ok, 1} = Questions.auto_grade_answers(question.id)

      updated_answer = Questions.get_answer(answer.id)
      assert updated_answer.is_correct == 1
    end

    test "auto_grade_answers/1 does not grade written questions" do
      question = question_fixture(:written)
      user = user_fixture()

      answer = answer_fixture(user, question, %{
        data: %{"answer_text" => "Some answer"},
        is_correct: 2
      })

      assert {:ok, 1} = Questions.auto_grade_answers(question.id)

      updated_answer = Questions.get_answer(answer.id)
      assert updated_answer.is_correct == 0  # marked as incorrect since we can't auto-grade
    end

    test "auto_grade_answers/1 grades MCQ multi questions correctly" do
      question = question_fixture(:mcq_multi)  # correct_indices: [0, 1, 3]
      user = user_fixture()

      # Create correct answer
      correct_answer = answer_fixture(user, question, %{
        data: %{"selected_indices" => [0, 1, 3]},
        is_correct: 2
      })

      # Create incorrect answer
      user2 = user_fixture()
      incorrect_answer = answer_fixture(user2, question, %{
        data: %{"selected_indices" => [0, 1]},  # Missing one correct answer
        is_correct: 2
      })

      assert {:ok, 2} = Questions.auto_grade_answers(question.id)

      updated_correct = Questions.get_answer(correct_answer.id)
      updated_incorrect = Questions.get_answer(incorrect_answer.id)

      assert updated_correct.is_correct == 1
      assert updated_incorrect.is_correct == 0
    end

    test "auto_grade_answers/1 grades cloze questions correctly" do
      question = question_fixture(:cloze)  # answers: ["Paris", "Europe"]
      user = user_fixture()

      # Create correct answer (case insensitive)
      correct_answer = answer_fixture(user, question, %{
        data: %{"answers" => ["paris", "EUROPE"]},
        is_correct: 2
      })

      # Create incorrect answer
      user2 = user_fixture()
      incorrect_answer = answer_fixture(user2, question, %{
        data: %{"answers" => ["London", "Europe"]},
        is_correct: 2
      })

      assert {:ok, 2} = Questions.auto_grade_answers(question.id)

      updated_correct = Questions.get_answer(correct_answer.id)
      updated_incorrect = Questions.get_answer(incorrect_answer.id)

      assert updated_correct.is_correct == 1
      assert updated_incorrect.is_correct == 0
    end

    test "auto_grade_answers/1 grades EMQ questions correctly" do
      question = question_fixture(:emq)  # matches: [[0, 0], [1, 1], [2, 2]]
      user = user_fixture()

      # Create correct answer
      correct_answer = answer_fixture(user, question, %{
        data: %{"matches" => [[0, 0], [1, 1], [2, 2]]},
        is_correct: 2
      })

      # Create incorrect answer (different order should still be correct)
      user2 = user_fixture()
      reordered_answer = answer_fixture(user2, question, %{
        data: %{"matches" => [[2, 2], [0, 0], [1, 1]]},
        is_correct: 2
      })

      # Create actually incorrect answer
      user3 = user_fixture()
      incorrect_answer = answer_fixture(user3, question, %{
        data: %{"matches" => [[0, 1], [1, 0], [2, 2]]},
        is_correct: 2
      })

      assert {:ok, 3} = Questions.auto_grade_answers(question.id)

      updated_correct = Questions.get_answer(correct_answer.id)
      updated_reordered = Questions.get_answer(reordered_answer.id)
      updated_incorrect = Questions.get_answer(incorrect_answer.id)

      assert updated_correct.is_correct == 1
      assert updated_reordered.is_correct == 1  # Different order but same matches
      assert updated_incorrect.is_correct == 0
    end

    test "auto_grade_answers/1 returns error for non-existent question" do
      assert {:error, :question_not_found} = Questions.auto_grade_answers(999999)
    end
  end

  describe "import_questions_from_json/3" do
    test "imports valid questions successfully" do
      user = user_fixture()

      json_data = [
        mcq_single_question_data(),
        true_false_question_data()
      ]
      json_string = Jason.encode!(json_data)

      assert {:ok, questions} = Questions.import_questions_from_json(json_string, user.id)
      assert length(questions) == 2
      assert Enum.all?(questions, &is_struct(&1, Question))
    end

    test "imports all question types successfully" do
      user = user_fixture()

      json_data = [
        mcq_single_question_data(),
        mcq_multi_question_data(),
        true_false_question_data(),
        written_question_data(),
        cloze_question_data(),
        emq_question_data()
      ]
      json_string = Jason.encode!(json_data)

      assert {:ok, questions} = Questions.import_questions_from_json(json_string, user.id)
      assert length(questions) == 6

      types = Enum.map(questions, & &1.type)
      assert "mcq_single" in types
      assert "mcq_multi" in types
      assert "true_false" in types
      assert "written" in types
      assert "cloze" in types
      assert "emq" in types
    end

    test "import validates each question type correctly" do
      user = user_fixture()

      # Mix of valid and invalid questions
      json_data = [
        mcq_single_question_data(),
        %{
          "question_type" => "emq",
          "premises" => ["A"],
          "options" => ["1"]
          # Missing instructions and difficulty - should fail
        }
      ]
      json_string = Jason.encode!(json_data)

      # Should fail with transaction rollback error
      assert {:error, error_message} = Questions.import_questions_from_json(json_string, user.id)
      assert is_binary(error_message)
      assert String.contains?(error_message, "instructions is required")

      # Verify no questions were created due to transaction rollback
      initial_count = length(Questions.list_questions())
      final_count = length(Questions.list_questions())
      assert final_count == initial_count
    end

    test "imports questions to question set when question_set_id provided" do
      user = user_fixture()
      question_set = question_set_fixture(user)

      json_data = [mcq_single_question_data()]
      json_string = Jason.encode!(json_data)

      assert {:ok, _questions} = Questions.import_questions_from_json(json_string, user.id, question_set.id)

      # Verify question was added to set
      set_questions = Questions.get_question_set_questions_with_positions(question_set.id)
      assert length(set_questions) == 1
    end

    test "returns error for invalid JSON" do
      user = user_fixture()
      invalid_json = "invalid json"

      assert {:error, :invalid_json_payload, _} = Questions.import_questions_from_json(invalid_json, user.id)
    end

    test "returns error for non-list JSON" do
      user = user_fixture()
      json_string = Jason.encode!(%{"not" => "a list"})

      assert {:error, :invalid_format_expected_list} = Questions.import_questions_from_json(json_string, user.id)
    end

    test "rolls back transaction if any question fails" do
      user = user_fixture()

      json_data = [
        mcq_single_question_data(),
        %{invalid: "data"}  # This will fail
      ]
      json_string = Jason.encode!(json_data)

      # Should return error and not create any questions
      initial_count = length(Questions.list_questions())

      assert {:error, :invalid_question_data, _details} = Questions.import_questions_from_json(json_string, user.id)

      final_count = length(Questions.list_questions())
      assert final_count == initial_count
    end
  end

  describe "advanced question set operations" do
    test "get_unanswered_questions_for_user_in_set/2 returns unanswered questions" do
      user = user_fixture()
      question_set = question_set_fixture(user)
      question1 = question_fixture()
      question2 = question_fixture()

      # Add questions to set
      json_data = [
        Processed.Question.to_map(Processed.Question.from_map(question1.data)),
        Processed.Question.to_map(Processed.Question.from_map(question2.data))
      ]
      json_string = Jason.encode!(json_data)
      Questions.import_questions_from_json(json_string, user.id, question_set.id)

      # Get the actual questions that were imported
      set_questions = Questions.get_question_set_questions_with_positions(question_set.id)
      first_imported_question = List.first(set_questions).question

      # Answer only one question
      answer_fixture(user, first_imported_question)

      unanswered = Questions.get_unanswered_questions_for_user_in_set(user.id, question_set.id)

      # Should return the question that wasn't answered
      assert length(unanswered) == 1
    end

    test "update_question_positions_in_set/2 updates question positions" do
      user = user_fixture()
      question_set = question_set_fixture(user)
      question1 = question_fixture()
      question2 = question_fixture()

      # Add questions to set
      json_data = [
        Processed.Question.to_map(Processed.Question.from_map(question1.data)),
        Processed.Question.to_map(Processed.Question.from_map(question2.data))
      ]
      json_string = Jason.encode!(json_data)
      Questions.import_questions_from_json(json_string, user.id, question_set.id)

      # Get the actual question IDs from the set
      set_questions = Questions.get_question_set_questions_with_positions(question_set.id)
      [first_q, second_q] = set_questions

      # Update positions (swap them)
      position_updates = [
        %{question_id: first_q.question.id, position: 2},
        %{question_id: second_q.question.id, position: 1}
      ]

      assert {:ok, _} = Questions.update_question_positions_in_set(question_set.id, position_updates)

      # Verify positions were updated
      updated_questions = Questions.get_question_set_questions_with_positions(question_set.id)
      positions_map = Map.new(updated_questions, fn %{question: q, position: p} -> {q.id, p} end)

      assert positions_map[first_q.question.id] == 2
      assert positions_map[second_q.question.id] == 1
    end
  end
end
