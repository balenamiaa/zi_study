defmodule ZiStudy.QuestionsTest do
  use ZiStudy.DataCase

  import ZiStudy.Fixtures

  alias ZiStudy.Questions
  alias ZiStudy.Questions.{Question, QuestionSet, Tag, Answer}
  alias ZiStudy.QuestionsOps.Processed
  alias ZiStudyWeb.Live.ActiveLearning.QuestionHandlers

  describe "question_sets" do
    test "list_question_sets/0 returns all public question sets" do
      public_set = question_set_fixture()
      user = user_fixture()
      private_set = question_set_fixture(user, %{is_private: true})

      sets = Questions.list_question_sets()

      assert public_set in sets
      refute private_set in sets
    end

    test "list_question_sets/2 with user_id and show_only_owned parameter" do
      user = user_fixture()
      other_user = user_fixture()

      user_public = question_set_fixture(user, %{is_private: false})
      user_private = question_set_fixture(user, %{is_private: true})
      other_public = question_set_fixture(other_user, %{is_private: false})
      other_private = question_set_fixture(other_user, %{is_private: true})

      # Get only user's owned sets (both private and public)
      owned_sets = Questions.list_question_sets(user.id, true)
      assert user_public in owned_sets
      assert user_private in owned_sets
      # Other user's sets should not be included
      refute other_public in owned_sets
      refute other_private in owned_sets

      # Get user's owned sets + all public sets from others
      all_accessible_sets = Questions.list_question_sets(user.id, false)
      assert user_public in all_accessible_sets
      assert user_private in all_accessible_sets
      # Public sets from other users should be included
      assert other_public in all_accessible_sets
      refute other_private in all_accessible_sets
    end

    test "get_question_set/1 returns the question set with id" do
      question_set = question_set_fixture()
      assert Questions.get_question_set(question_set.id).id == question_set.id
    end

    test "get_question_set/1 returns nil for non-existent id" do
      assert Questions.get_question_set(999_999) == nil
    end

    test "create_question_set/2 with valid data creates a question set" do
      user = user_fixture()
      valid_attrs = valid_question_set_attributes()

      assert {:ok, %QuestionSet{} = question_set} =
               Questions.create_question_set(user, valid_attrs)

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

      assert {:ok, %QuestionSet{} = question_set} =
               Questions.create_question_set_ownerless(valid_attrs)

      assert question_set.title == valid_attrs["title"]
      assert question_set.owner_id == nil
      assert question_set.is_private == false
    end

    test "create_question_set_ownerless/1 creates question set with tags" do
      tag1 = tag_fixture(%{name: "Surgery"})
      tag2 = tag_fixture(%{name: "Stage 4"})

      valid_attrs = Map.merge(valid_question_set_attributes(), %{
        tags: [tag1, tag2]
      })

      assert {:ok, %QuestionSet{} = question_set} =
               Questions.create_question_set_ownerless(valid_attrs)

      # Reload to get tags
      question_set_with_tags = Questions.get_question_set(question_set.id)

      assert question_set_with_tags.title == valid_attrs["title"]
      assert question_set_with_tags.owner_id == nil
      assert question_set_with_tags.is_private == false

      tag_names = Enum.map(question_set_with_tags.tags, & &1.name)
      assert "Surgery" in tag_names
      assert "Stage 4" in tag_names
      assert length(question_set_with_tags.tags) == 2
    end

    test "create_question_set_ownerless/1 works without tags" do
      valid_attrs = valid_question_set_attributes()

      assert {:ok, %QuestionSet{} = question_set} =
               Questions.create_question_set_ownerless(valid_attrs)

      question_set_with_tags = Questions.get_question_set(question_set.id)
      assert length(question_set_with_tags.tags) == 0
    end

    test "update_question_set/2 with valid data updates the question set" do
      question_set = question_set_fixture()
      update_attrs = %{title: "Updated Title", description: "Updated Description"}

      assert {:ok, %QuestionSet{} = question_set} =
               Questions.update_question_set(question_set, update_attrs)

      assert question_set.title == "Updated Title"
      assert question_set.description == "Updated Description"
    end

    test "update_question_set/2 with invalid data returns error changeset" do
      question_set = question_set_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Questions.update_question_set(question_set, %{title: nil})

      # Compare essential fields rather than full structs to avoid association loading differences
      updated_question_set = Questions.get_question_set(question_set.id)
      assert question_set.id == updated_question_set.id
      assert question_set.title == updated_question_set.title
      assert question_set.description == updated_question_set.description
      assert question_set.is_private == updated_question_set.is_private
      assert question_set.owner_id == updated_question_set.owner_id
    end

    test "update_question_set/2 with tags updates the question set tags" do
      question_set = question_set_fixture()
      tag1 = tag_fixture(%{name: "Surgery"})
      tag2 = tag_fixture(%{name: "Medicine"})

      # Update with tags
      update_attrs = %{
        title: "Updated Title",
        tags: [tag1, tag2]
      }

      assert {:ok, %QuestionSet{} = updated_set} =
               Questions.update_question_set(question_set, update_attrs)

      assert updated_set.title == "Updated Title"

      # Reload to get tags
      reloaded_set = Questions.get_question_set(updated_set.id)
      tag_names = Enum.map(reloaded_set.tags, & &1.name) |> Enum.sort()
      assert tag_names == ["Medicine", "Surgery"]
      assert length(reloaded_set.tags) == 2
    end

    test "update_question_set/2 with string key tags updates the question set tags" do
      question_set = question_set_fixture()
      tag1 = tag_fixture(%{name: "Biology"})
      tag2 = tag_fixture(%{name: "Anatomy"})

      # Update with tags using string keys
      update_attrs = %{
        "title" => "Updated Title",
        "tags" => [tag1, tag2]
      }

      assert {:ok, %QuestionSet{} = updated_set} =
               Questions.update_question_set(question_set, update_attrs)

      assert updated_set.title == "Updated Title"

      # Reload to get tags
      reloaded_set = Questions.get_question_set(updated_set.id)
      tag_names = Enum.map(reloaded_set.tags, & &1.name) |> Enum.sort()
      assert tag_names == ["Anatomy", "Biology"]
      assert length(reloaded_set.tags) == 2
    end

        test "update_question_set/2 without tags doesn't affect existing tags" do
      question_set = question_set_fixture()
      _tag1 = tag_fixture(%{name: "Existing"})

      # First, add a tag via add_tags_to_question_set
      {:ok, set_with_tag} = Questions.add_tags_to_question_set(question_set, ["Existing"])

      # Update without mentioning tags
      update_attrs = %{title: "Updated Title"}

      assert {:ok, %QuestionSet{} = updated_set} =
               Questions.update_question_set(set_with_tag, update_attrs)

      assert updated_set.title == "Updated Title"

      # Reload to get tags - should still have the existing tag
      reloaded_set = Questions.get_question_set(updated_set.id)
      assert length(reloaded_set.tags) == 1
      assert hd(reloaded_set.tags).name == "Existing"
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
      assert Questions.get_question(999_999) == nil
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
      question1 =
        question_fixture(:mcq_single, %{"question_text" => "What is the capital of France?"})

      question2 = question_fixture(:mcq_single, %{"question_text" => "What is 2 + 2?"})

      results = Questions.search_questions("France")
      assert question1 in results
      refute question2 in results
    end

    test "search_questions/1 works with different question types" do
      mcq_question = question_fixture(:mcq_single, %{"question_text" => "Mathematics problem"})
      written_question = question_fixture(:written, %{"question_text" => "Explain mathematics"})

      cloze_question =
        question_fixture(:cloze, %{"question_text" => "The study of mathematics is ___"})

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
      question =
        question_fixture(:mcq_single, %{"question_text" => "What is the CAPITAL of France?"})

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

      assert {:ok, %Processed.Question.McqSingle{} = processed} =
               Questions.get_question_as_processed(question.id)

      assert processed.question_text == question.data["question_text"]
    end

    test "get_question_as_processed/1 returns nil for non-existent question" do
      assert Questions.get_question_as_processed(999_999) == nil
    end
  end

  describe "question sets and questions association" do
    test "get_question_set_questions_with_positions/1 returns questions with positions" do
      question_set = question_set_fixture()
      question1 = question_fixture()
      question2 = question_fixture()

      # Add questions to set
      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      {:ok, _} = Questions.add_questions_to_set(question_set, [question1, question2], user.id)

      results = Questions.get_question_set_questions_with_positions(question_set.id)
      assert length(results) == 2
      assert Enum.all?(results, &Map.has_key?(&1, :position))
    end

    test "remove_questions_from_set/2 removes questions from set" do
      question_set = question_set_fixture()
      question = question_fixture()

      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      {:ok, _} = Questions.add_questions_to_set(question_set, [question], user.id)

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
      {:ok, _} = Questions.add_questions_to_set(source_set, [question], user.id)

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

      assert {:ok, _updated_set} =
               Questions.add_questions_to_set(question_set, [question1, question2], user.id)

      questions_in_set = Questions.get_question_set_questions_with_positions(question_set.id)
      question_ids = Enum.map(questions_in_set, & &1.question.id)

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

      assert {:ok, _updated_set} =
               Questions.add_questions_to_set(question_set, [question1.id, question2.id], user.id)

      questions_in_set = Questions.get_question_set_questions_with_positions(question_set.id)
      question_ids = Enum.map(questions_in_set, & &1.question.id)

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

      assert {:ok, _updated_set} =
               Questions.add_questions_to_set(question_set, questions_with_positions, user.id)

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

      assert {:ok, _updated_set} =
               Questions.add_questions_to_set(question_set, questions_as_maps, user.id)

      questions_in_set = Questions.get_question_set_questions_with_positions(question_set.id)
      question_ids = Enum.map(questions_in_set, & &1.question.id)

      assert question1.id in question_ids
      assert question2.id in question_ids
      assert length(questions_in_set) == 2
    end

    test "add_questions_to_set/3 appends to existing questions in set" do
      question_set = question_set_fixture()
      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      # Add initial question
      initial_question = question_fixture()
      {:ok, _} = Questions.add_questions_to_set(question_set, [initial_question], user.id)

      # Add more questions using our new function
      question1 = question_fixture()
      question2 = question_fixture()

      assert {:ok, _updated_set} =
               Questions.add_questions_to_set(question_set, [question1, question2], user.id)

      questions_in_set = Questions.get_question_set_questions_with_positions(question_set.id)
      assert length(questions_in_set) == 3

      # Verify the new questions have higher positions
      positions = Enum.map(questions_in_set, & &1.position) |> Enum.sort()
      assert positions == [1, 2, 3]
    end

    test "add_questions_to_set/3 without user_id works for any question set" do
      question_set = question_set_fixture()
      question1 = question_fixture()
      question2 = question_fixture()

      # Should work without authorization
      assert {:ok, _updated_set} =
               Questions.add_questions_to_set(question_set, [question1, question2])

      questions_in_set = Questions.get_question_set_questions_with_positions(question_set.id)
      question_ids = Enum.map(questions_in_set, & &1.question.id)

      assert question1.id in question_ids
      assert question2.id in question_ids
    end

    test "add_questions_to_set/3 returns error for unauthorized user" do
      user1 = user_fixture()
      user2 = user_fixture()
      # owned by user1
      question_set = question_set_fixture(user1)
      question = question_fixture()

      # user2 tries to add questions to user1's set
      assert {:error, :unauthorized} =
               Questions.add_questions_to_set(question_set, [question], user2.id)

      # Verify no questions were added
      questions_in_set = Questions.get_question_set_questions_with_positions(question_set.id)
      assert length(questions_in_set) == 0
    end

    test "add_questions_to_set/3 returns error for empty question list" do
      question_set = question_set_fixture()
      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      assert {:error, :no_valid_questions} =
               Questions.add_questions_to_set(question_set, [], user.id)
    end

    test "add_questions_to_set/3 returns error for invalid question data" do
      question_set = question_set_fixture()
      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      invalid_questions = ["invalid", %{invalid: "data"}, nil]

      assert {:error, :no_valid_questions} =
               Questions.add_questions_to_set(question_set, invalid_questions, user.id)
    end

    test "add_questions_to_set/3 handles mixed valid and invalid questions" do
      question_set = question_set_fixture()
      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      question1 = question_fixture()
      mixed_questions = [question1, "invalid", %{invalid: "data"}]

      assert {:ok, _updated_set} =
               Questions.add_questions_to_set(question_set, mixed_questions, user.id)

      questions_in_set = Questions.get_question_set_questions_with_positions(question_set.id)
      assert length(questions_in_set) == 1
      assert List.first(questions_in_set).question.id == question1.id
    end

    test "add_questions_to_set/3 handles duplicate questions gracefully" do
      question_set = question_set_fixture()
      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      question = question_fixture()

      # Add question first time
      assert {:ok, _} = Questions.add_questions_to_set(question_set, [question], user.id)
      # Add same question second time - should skip duplicates
      assert {:ok, _, %{skipped_duplicates: 1}} =
               Questions.add_questions_to_set(question_set, [question], user.id)

      questions_in_set = Questions.get_question_set_questions_with_positions(question_set.id)
      # Should have the question only once (duplicates are now prevented)
      assert length(questions_in_set) == 1
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

      assert {:ok, updated_set} =
               Questions.add_tags_to_question_set(question_set, [tag1.name, tag2.name])

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

    test "list_answers_for_question/1 returns all answers for a question", %{
      user: user,
      question: question
    } do
      answer = answer_fixture(user, question)
      answers = Questions.list_answers_for_question(question.id)
      assert answer.id in Enum.map(answers, & &1.id)
    end

    test "list_answers_for_user/1 returns all answers for a user", %{
      user: user,
      question: question
    } do
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
      assert Questions.get_answer(999_999) == nil
    end

    test "get_user_answer/2 returns answer for user-question combination", %{
      user: user,
      question: question
    } do
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

      assert {:ok, %Answer{} = answer} =
               Questions.upsert_answer(user.id, question.id, answer_data, 1)

      assert answer.data == answer_data
      assert answer.is_correct == 1
    end

    test "upsert_answer/4 updates existing answer", %{user: user, question: question} do
      # Create initial answer
      initial_answer = answer_fixture(user, question)

      # Upsert with new data
      new_data = %{"selected_index" => 3}

      assert {:ok, %Answer{} = updated_answer} =
               Questions.upsert_answer(user.id, question.id, new_data, 0)

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

    test "get_user_answers_for_questions/2 returns answers for user and list of questions", %{
      user: user
    } do
      # Create multiple questions
      question1 = question_fixture(:mcq_single)
      question2 = question_fixture(:true_false)
      question3 = question_fixture(:written)

      # Create answers for some questions
      answer1 = answer_fixture(user, question1)
      answer2 = answer_fixture(user, question2)
      # No answer for question3

      # Test with Question structs
      questions = [question1, question2, question3]
      answers = Questions.get_user_answers_for_questions(user.id, questions)

      # Should return only the answers that exist
      assert length(answers) == 2
      answer_ids = Enum.map(answers, & &1.id)
      assert answer1.id in answer_ids
      assert answer2.id in answer_ids

      # Verify associations are preloaded
      first_answer = List.first(answers)
      assert first_answer.user.id == user.id
      assert first_answer.question != nil
    end

    test "get_user_answers_for_questions/2 works with partial Question structs", %{user: user} do
      question1 = question_fixture(:mcq_single)
      question2 = question_fixture(:true_false)

      answer1 = answer_fixture(user, question1)
      answer2 = answer_fixture(user, question2)

      # Test with partial structs (only id field)
      questions = [%Question{id: question1.id}, %Question{id: question2.id}]
      answers = Questions.get_user_answers_for_questions(user.id, questions)

      assert length(answers) == 2
      answer_ids = Enum.map(answers, & &1.id)
      assert answer1.id in answer_ids
      assert answer2.id in answer_ids
    end

    test "get_user_answers_for_questions/2 works with maps containing id", %{user: user} do
      question1 = question_fixture(:mcq_single)
      question2 = question_fixture(:true_false)

      answer1 = answer_fixture(user, question1)
      answer2 = answer_fixture(user, question2)

      # Test with maps
      questions = [%{id: question1.id}, %{id: question2.id}]
      answers = Questions.get_user_answers_for_questions(user.id, questions)

      assert length(answers) == 2
      answer_ids = Enum.map(answers, & &1.id)
      assert answer1.id in answer_ids
      assert answer2.id in answer_ids
    end

    test "get_user_answers_for_questions/2 works with integer IDs", %{user: user} do
      question1 = question_fixture(:mcq_single)
      question2 = question_fixture(:true_false)

      answer1 = answer_fixture(user, question1)
      answer2 = answer_fixture(user, question2)

      # Test with raw integer IDs
      questions = [question1.id, question2.id]
      answers = Questions.get_user_answers_for_questions(user.id, questions)

      assert length(answers) == 2
      answer_ids = Enum.map(answers, & &1.id)
      assert answer1.id in answer_ids
      assert answer2.id in answer_ids
    end

    test "get_user_answers_for_questions/2 handles mixed input types", %{user: user} do
      question1 = question_fixture(:mcq_single)
      question2 = question_fixture(:true_false)
      question3 = question_fixture(:written)

      answer1 = answer_fixture(user, question1)
      answer2 = answer_fixture(user, question2)
      answer3 = answer_fixture(user, question3)

      # Mix different input types
      questions = [
        # Full Question struct
        question1,
        # Partial Question struct
        %Question{id: question2.id},
        # Map with id
        %{id: question3.id},
        # Raw integer (duplicate, should be handled)
        question1.id
      ]

      answers = Questions.get_user_answers_for_questions(user.id, questions)

      # Should handle duplicates and return unique answers
      assert length(answers) == 3
      answer_ids = Enum.map(answers, & &1.id)
      assert answer1.id in answer_ids
      assert answer2.id in answer_ids
      assert answer3.id in answer_ids
    end

    test "get_user_answers_for_questions/2 returns empty list for user with no answers" do
      user_with_no_answers = user_fixture()
      question1 = question_fixture(:mcq_single)
      question2 = question_fixture(:true_false)

      questions = [question1, question2]
      answers = Questions.get_user_answers_for_questions(user_with_no_answers.id, questions)

      assert answers == []
    end

    test "get_user_answers_for_questions/2 returns empty list for empty question list", %{
      user: user
    } do
      answers = Questions.get_user_answers_for_questions(user.id, [])
      assert answers == []
    end

    test "get_user_answers_for_questions/2 filters out invalid questions", %{user: user} do
      question1 = question_fixture(:mcq_single)
      answer1 = answer_fixture(user, question1)

      # Mix valid and invalid inputs
      questions = [
        # Valid
        question1,
        # Invalid - no id
        %{invalid: "data"},
        # Invalid - nil
        nil,
        # Invalid - nil id
        %{id: nil},
        # Valid format but non-existent question
        999_999
      ]

      answers = Questions.get_user_answers_for_questions(user.id, questions)

      # Should only return answer for the valid existing question
      assert length(answers) == 1
      assert List.first(answers).id == answer1.id
    end

    test "get_user_answers_for_questions/2 only returns answers for the specified user", %{
      user: user
    } do
      other_user = user_fixture()
      question1 = question_fixture(:mcq_single)
      question2 = question_fixture(:true_false)

      # Create answers for both users
      user_answer = answer_fixture(user, question1)
      other_user_answer = answer_fixture(other_user, question1)
      # Another answer for other user
      answer_fixture(other_user, question2)

      questions = [question1, question2]
      answers = Questions.get_user_answers_for_questions(user.id, questions)

      # Should only return the answer for the specified user
      assert length(answers) == 1
      assert List.first(answers).id == user_answer.id
      refute other_user_answer.id in Enum.map(answers, & &1.id)
    end

    test "get_user_answers_for_questions/2 handles large number of questions efficiently", %{
      user: user
    } do
      # Create many questions and answers
      questions_and_answers =
        Enum.map(1..50, fn _ ->
          question = question_fixture(:mcq_single)
          answer = answer_fixture(user, question)
          {question, answer}
        end)

      questions = Enum.map(questions_and_answers, fn {question, _} -> question end)
      expected_answer_ids = Enum.map(questions_and_answers, fn {_, answer} -> answer.id end)

      # Should efficiently fetch all answers in a single query
      answers = Questions.get_user_answers_for_questions(user.id, questions)

      assert length(answers) == 50
      actual_answer_ids = Enum.map(answers, & &1.id)
      assert MapSet.new(expected_answer_ids) == MapSet.new(actual_answer_ids)
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

    test "get_user_answer_stats/1 returns correct statistics", %{
      user1: user1,
      question1: question1,
      question2: question2
    } do
      # Create different types of answers
      correct_answer_fixture(user1, question1, %{is_correct: 1})
      incorrect_answer_fixture(user1, question2, %{is_correct: 0})
      # unevaluated
      answer_fixture(user1, question_fixture(), %{is_correct: 2})

      stats = Questions.get_user_answer_stats(user1.id)

      assert stats.total_answers == 3
      assert stats.correct_answers == 1
      assert stats.incorrect_answers == 1
      assert stats.unevaluated_answers == 1
    end

    test "get_question_answer_stats/1 returns correct statistics", %{
      user1: user1,
      user2: user2,
      question1: question1
    } do
      # Create different answers for the same question
      correct_answer_fixture(user1, question1, %{is_correct: 1})
      incorrect_answer_fixture(user2, question1, %{is_correct: 0})

      stats = Questions.get_question_answer_stats(question1.id)

      assert stats.total_answers == 2
      assert stats.correct_answers == 1
      assert stats.incorrect_answers == 1
      assert stats.unevaluated_answers == 0
    end

    test "get_user_question_set_stats/2 returns stats for user on specific question set", %{
      user1: user1,
      question1: question1
    } do
      question_set = question_set_fixture()
      user = user_fixture()
      Questions.update_question_set(question_set, %{owner_id: user.id})

      # Add question to set
      {:ok, _} = Questions.add_questions_to_set(question_set, [question1], user.id)

      # Create answer for the question
      correct_answer_fixture(user1, question1, %{is_correct: 1})

      stats = Questions.get_user_question_set_stats(user1.id, question_set.id)

      assert stats.total_answers == 1
      assert stats.correct_answers == 1
    end
  end

  describe "auto grading" do
    test "auto_grade_answers/1 grades MCQ single questions correctly" do
      # correct_index: 1
      question = question_fixture(:mcq_single)
      user = user_fixture()

      # Create correct answer
      correct_answer =
        answer_fixture(user, question, %{
          data: %{"selected_index" => 1},
          # unevaluated
          is_correct: 2
        })

      # Create incorrect answer
      user2 = user_fixture()

      incorrect_answer =
        answer_fixture(user2, question, %{
          data: %{"selected_index" => 0},
          # unevaluated
          is_correct: 2
        })

      assert {:ok, 2} = Questions.auto_grade_answers(question.id)

      # Check that answers were graded
      updated_correct = Questions.get_answer(correct_answer.id)
      updated_incorrect = Questions.get_answer(incorrect_answer.id)

      assert updated_correct.is_correct == 1
      assert updated_incorrect.is_correct == 0
    end

    test "auto_grade_answers/1 grades true/false questions correctly" do
      # is_correct_true: true
      question = question_fixture(:true_false)
      user = user_fixture()

      answer =
        answer_fixture(user, question, %{
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

      answer =
        answer_fixture(user, question, %{
          data: %{"answer_text" => "Some answer"},
          is_correct: 2
        })

      assert {:ok, 1} = Questions.auto_grade_answers(question.id)

      updated_answer = Questions.get_answer(answer.id)
      # marked as incorrect since we can't auto-grade
      assert updated_answer.is_correct == 0
    end

    test "auto_grade_answers/1 grades MCQ multi questions correctly" do
      # correct_indices: [0, 1, 3]
      question = question_fixture(:mcq_multi)
      user = user_fixture()

      # Create correct answer
      correct_answer =
        answer_fixture(user, question, %{
          data: %{"selected_indices" => [0, 1, 3]},
          is_correct: 2
        })

      # Create incorrect answer
      user2 = user_fixture()

      incorrect_answer =
        answer_fixture(user2, question, %{
          # Missing one correct answer
          data: %{"selected_indices" => [0, 1]},
          is_correct: 2
        })

      assert {:ok, 2} = Questions.auto_grade_answers(question.id)

      updated_correct = Questions.get_answer(correct_answer.id)
      updated_incorrect = Questions.get_answer(incorrect_answer.id)

      assert updated_correct.is_correct == 1
      assert updated_incorrect.is_correct == 0
    end

    test "auto_grade_answers/1 grades cloze questions correctly" do
      # answers: ["Paris", "Europe"]
      question = question_fixture(:cloze)
      user = user_fixture()

      # Create correct answer (case insensitive)
      correct_answer =
        answer_fixture(user, question, %{
          data: %{"answers" => ["paris", "EUROPE"]},
          is_correct: 2
        })

      # Create incorrect answer
      user2 = user_fixture()

      incorrect_answer =
        answer_fixture(user2, question, %{
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
      # matches: [[0, 0], [1, 1], [2, 2]]
      question = question_fixture(:emq)
      user = user_fixture()

      # Create correct answer
      correct_answer =
        answer_fixture(user, question, %{
          data: %{"matches" => [[0, 0], [1, 1], [2, 2]]},
          is_correct: 2
        })

      # Create incorrect answer (different order should still be correct)
      user2 = user_fixture()

      reordered_answer =
        answer_fixture(user2, question, %{
          data: %{"matches" => [[2, 2], [0, 0], [1, 1]]},
          is_correct: 2
        })

      # Create actually incorrect answer
      user3 = user_fixture()

      incorrect_answer =
        answer_fixture(user3, question, %{
          data: %{"matches" => [[0, 1], [1, 0], [2, 2]]},
          is_correct: 2
        })

      assert {:ok, 3} = Questions.auto_grade_answers(question.id)

      updated_correct = Questions.get_answer(correct_answer.id)
      updated_reordered = Questions.get_answer(reordered_answer.id)
      updated_incorrect = Questions.get_answer(incorrect_answer.id)

      assert updated_correct.is_correct == 1
      # Different order but same matches
      assert updated_reordered.is_correct == 1
      assert updated_incorrect.is_correct == 0
    end

    test "auto_grade_answers/1 returns error for non-existent question" do
      assert {:error, :question_not_found} = Questions.auto_grade_answers(999_999)
    end
  end

  describe "import_questions_from_json/3" do
    test "imports valid questions successfully" do
      user = user_fixture()

      json_data = [
        mcq_single_import_data(),
        true_false_import_data()
      ]

      json_string = Jason.encode!(json_data)

      assert {:ok, questions} = Questions.import_questions_from_json(json_string, user.id)
      assert length(questions) == 2
      assert Enum.all?(questions, &is_struct(&1, Question))
    end

    test "imports all question types successfully" do
      user = user_fixture()

      json_data = [
        mcq_single_import_data(),
        mcq_multi_import_data(),
        true_false_import_data(),
        written_import_data(),
        cloze_import_data(),
        emq_import_data()
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
        mcq_single_import_data(),
        %{
          "temp_id" => "bad_emq",
          "question_type" => "emq",
          "premises" => ["A"],
          "options" => ["1"]
          # Missing instructions and difficulty - should fail
        }
      ]

      json_string = Jason.encode!(json_data)

      # Should fail with invalid question data error
      assert {:error, :invalid_question_data, _details} = Questions.import_questions_from_json(json_string, user.id)

      # Verify no questions were created due to transaction rollback
      initial_count = length(Questions.list_questions())
      final_count = length(Questions.list_questions())
      assert final_count == initial_count
    end

    test "imports questions to question set when question_set_id provided" do
      user = user_fixture()
      question_set = question_set_fixture(user)

      json_data = [mcq_single_import_data()]
      json_string = Jason.encode!(json_data)

      assert {:ok, _questions} =
               Questions.import_questions_from_json(json_string, user.id, question_set.id)

      # Verify question was added to set
      set_questions = Questions.get_question_set_questions_with_positions(question_set.id)
      assert length(set_questions) == 1
    end

    test "returns error for invalid JSON" do
      user = user_fixture()
      invalid_json = "invalid json"

      assert {:error, :invalid_json_payload, _} =
               Questions.import_questions_from_json(invalid_json, user.id)
    end

    test "returns error for non-list JSON" do
      user = user_fixture()
      json_string = Jason.encode!(%{"not" => "a list"})

      assert {:error, :invalid_format_expected_list} =
               Questions.import_questions_from_json(json_string, user.id)
    end

    test "rolls back transaction if any question fails" do
      user = user_fixture()

      json_data = [
        mcq_single_import_data(),
        # This will fail
        %{invalid: "data"}
      ]

      json_string = Jason.encode!(json_data)

      # Should return error and not create any questions
      initial_count = length(Questions.list_questions())

      assert {:error, :invalid_question_data, _details} =
               Questions.import_questions_from_json(json_string, user.id)

      final_count = length(Questions.list_questions())
      assert final_count == initial_count
    end

    test "imports questions with nil user_id (system import)" do
      json_data = [
        mcq_single_import_data(),
        true_false_import_data()
      ]

      json_string = Jason.encode!(json_data)

      # Test with explicit nil user_id
      assert {:ok, questions} = Questions.import_questions_from_json(json_string, nil)
      assert length(questions) == 2
      assert Enum.all?(questions, &is_struct(&1, Question))

      # Test with default nil user_id (function parameter default)
      assert {:ok, questions} = Questions.import_questions_from_json(json_string)
      assert length(questions) == 2
    end

    test "imports questions to ownerless question set with nil user_id" do
      # Create ownerless question set
      ownerless_set = Questions.create_question_set_ownerless(%{title: "System Set", description: "Ownerless set"})
      assert {:ok, question_set} = ownerless_set
      assert question_set.owner_id == nil

      json_data = [mcq_single_import_data()]
      json_string = Jason.encode!(json_data)

      # Should succeed with nil user_id
      assert {:ok, _questions} =
               Questions.import_questions_from_json(json_string, nil, question_set.id)

      # Verify question was added to set
      set_questions = Questions.get_question_set_questions_with_positions(question_set.id)
      assert length(set_questions) == 1
    end

    test "fails to import to owned question set with nil user_id" do
      user = user_fixture()
      user_owned_set = question_set_fixture(user)

      json_data = [mcq_single_import_data()]
      json_string = Jason.encode!(json_data)

      # Should fail when trying to add to owned set without user authorization
      assert {:error, error_message} =
               Questions.import_questions_from_json(json_string, nil, user_owned_set.id)

      assert String.contains?(error_message, "Cannot add questions to owned question set")
      assert String.contains?(error_message, "without user authorization")

      # Verify no questions were added to the set
      set_questions = Questions.get_question_set_questions_with_positions(user_owned_set.id)
      assert length(set_questions) == 0
    end

    test "import with nil user_id works without question_set_id" do
      json_data = [
        mcq_single_import_data(),
        written_import_data()
      ]

      json_string = Jason.encode!(json_data)

      initial_count = length(Questions.list_questions())

      # Should create questions without adding to any set
      assert {:ok, questions} = Questions.import_questions_from_json(json_string, nil, nil)
      assert length(questions) == 2

      final_count = length(Questions.list_questions())
      assert final_count == initial_count + 2
    end

         test "import_questions_from_json handles import format data correctly" do
       # Test with import format using fixture
       import_format_data = [mcq_single_import_data()]

       json_string = Jason.encode!(import_format_data)

       assert {:ok, questions} = Questions.import_questions_from_json(json_string, nil)
       assert length(questions) == 1

       question = List.first(questions)
       assert question.type == "mcq_single"
       assert question.data["correct_index"] == 1  # Should be converted from temp_id to index
       assert question.data["options"] == ["3", "4", "5", "6"]  # Should be converted to simple strings
       refute is_nil(question.data["correct_index"])  # Should not be null
    end

         test "import_questions_from_json fails with processed format data" do
       # Test with processed format (should fail since we expect import format)
       processed_format_data = [
         %{
           "question_type" => "mcq_single",
           "question_text" => "What is 2 + 2?",
           "options" => ["3", "4", "5"],  # This is processed format (strings)
           "correct_index" => 1,  # This is processed format field
           "difficulty" => "easy",
           "explanation" => "Simple addition"
           # Missing temp_id and import format fields
         }
       ]

       json_string = Jason.encode!(processed_format_data)

       # Should fail because it's not in import format
       assert {:error, :invalid_question_data, _details} =
         Questions.import_questions_from_json(json_string, nil)
     end

    test "import_questions_from_json handles EMQ import format correctly" do
      # Test EMQ with import format using fixture
      emq_import_data = [emq_import_data()]

      json_string = Jason.encode!(emq_import_data)

      assert {:ok, questions} = Questions.import_questions_from_json(json_string, nil)
      assert length(questions) == 1

      question = List.first(questions)
      assert question.type == "emq"
      assert question.data["premises"] == ["First planet", "Second planet", "Third planet"]  # Converted to strings
      assert question.data["options"] == ["Mercury", "Venus", "Earth", "Mars"]    # Converted to strings
      assert question.data["matches"] == [[0, 0], [1, 1], [2, 2]]      # Converted to indices
     end

     test "end-to-end: create ownerless set with tags and import questions" do
       # Simulate the user's exact scenario
       # 1. Create tags
       tag_names = ["Surgery", "Stage 4", "Stage 5", "Stage 6", "Final Exam", "Endblock Exam", "Moodle"]

       {tag_results, _} =
         Enum.reduce(tag_names, {[], 0}, fn tag_name, {acc, _} ->
           {:ok, tag} = Questions.create_tag(%{name: tag_name})
           {[tag | acc], 0}
         end)

       tags = Enum.reverse(tag_results)

       # 2. Create ownerless question set with tags
       {:ok, new_set} =
         Questions.create_question_set_ownerless(%{
           title: "Test Surgery Set",
           description: "A test set with tags and questions",
           tags: tags
         })

       # 3. Create JSON with import format data
       import_questions = [
         %{
           "temp_id" => "q1",
           "question_type" => "mcq_single",
           "difficulty" => "easy",
           "question_text" => "What is a scalpel used for?",
           "options" => [
             %{"temp_id" => "opt1", "text" => "Cutting"},
             %{"temp_id" => "opt2", "text" => "Measuring"},
             %{"temp_id" => "opt3", "text" => "Weighing"}
           ],
           "correct_option_temp_id" => "opt1",
           "explanation" => "A scalpel is a surgical knife"
         },
         %{
           "temp_id" => "q2",
           "question_type" => "true_false",
           "difficulty" => "medium",
           "question_text" => "Surgery requires sterile conditions",
           "is_correct_true" => true,
           "explanation" => "Sterile conditions prevent infection"
         }
       ]

       json_string = Jason.encode!(import_questions)

       # 4. Import questions with nil user_id and question_set_id
       {:ok, imported_questions} = Questions.import_questions_from_json(json_string, nil, new_set.id)

       # 5. Verify everything worked correctly
       assert length(imported_questions) == 2

       # Check questions were properly converted from import format
       mcq_question = Enum.find(imported_questions, &(&1.type == "mcq_single"))
       tf_question = Enum.find(imported_questions, &(&1.type == "true_false"))

       assert mcq_question.data["correct_index"] == 0  # Not null, converted from temp_id
       assert mcq_question.data["options"] == ["Cutting", "Measuring", "Weighing"]  # Converted to strings
       assert tf_question.data["is_correct_true"] == true

       # Check questions were added to the set
       actual_questions = Questions.get_question_set_questions_with_positions(new_set.id)
       assert length(actual_questions) == 2

       # Check tags were added to the set
       set_with_tags = Questions.get_question_set(new_set.id)
       tag_names_on_set = Enum.map(set_with_tags.tags, & &1.name)
       assert "Surgery" in tag_names_on_set
       assert "Stage 4" in tag_names_on_set
       assert length(set_with_tags.tags) == 7
     end
  end

  describe "advanced question set operations" do
    test "get_unanswered_questions_for_user_in_set/2 returns unanswered questions" do
      user = user_fixture()
      question_set = question_set_fixture(user)
      question1 = question_fixture()
      question2 = question_fixture()

      # Add questions to set
      {:ok, _} = Questions.add_questions_to_set(question_set, [question1, question2], user.id)

      # Answer only one question
      answer_fixture(user, question1)

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
      {:ok, _} = Questions.add_questions_to_set(question_set, [question1, question2], user.id)

      # Update positions (swap them)
      position_updates = [
        %{question_id: question1.id, position: 2},
        %{question_id: question2.id, position: 1}
      ]

      assert {:ok, _} =
               Questions.update_question_positions_in_set(question_set.id, position_updates)

      # Verify positions were updated
      updated_questions = Questions.get_question_set_questions_with_positions(question_set.id)
      positions_map = Map.new(updated_questions, fn %{question: q, position: p} -> {q.id, p} end)

      assert positions_map[question1.id] == 2
      assert positions_map[question2.id] == 1
    end
  end

  describe "answer correctness validation" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "check_answer_correctness/2 validates MCQ single answers correctly" do
      # correct_index: 1
      question = question_fixture(:mcq_single)

      # Test correct answer
      correct_answer = %{"selected_index" => 1}
      assert {:ok, true} = Questions.check_answer_correctness(question.id, correct_answer)

      # Test incorrect answer
      incorrect_answer = %{"selected_index" => 0}
      assert {:ok, false} = Questions.check_answer_correctness(question.id, incorrect_answer)

      # Test invalid index
      invalid_answer = %{"selected_index" => 99}

      assert {:error, :invalid_option_index} =
               Questions.check_answer_correctness(question.id, invalid_answer)

      # Test negative index
      negative_answer = %{"selected_index" => -1}

      assert {:error, :invalid_option_index} =
               Questions.check_answer_correctness(question.id, negative_answer)
    end

    test "check_answer_correctness/2 validates MCQ multi answers correctly" do
      # correct_indices: [0, 1, 3]
      question = question_fixture(:mcq_multi)

      # Test correct answer (exact match)
      correct_answer = %{"selected_indices" => [0, 1, 3]}
      assert {:ok, true} = Questions.check_answer_correctness(question.id, correct_answer)

      # Test correct answer (different order)
      reordered_answer = %{"selected_indices" => [3, 0, 1]}
      assert {:ok, true} = Questions.check_answer_correctness(question.id, reordered_answer)

      # Test incorrect answer (missing options)
      partial_answer = %{"selected_indices" => [0, 1]}
      assert {:ok, false} = Questions.check_answer_correctness(question.id, partial_answer)

      # Test incorrect answer (extra options)
      extra_answer = %{"selected_indices" => [0, 1, 2, 3]}
      assert {:ok, false} = Questions.check_answer_correctness(question.id, extra_answer)

      # Test invalid indices
      invalid_answer = %{"selected_indices" => [0, 1, 99]}

      assert {:error, :invalid_option_indices} =
               Questions.check_answer_correctness(question.id, invalid_answer)
    end

    test "check_answer_correctness/2 validates true/false answers correctly" do
      # is_correct_true: true
      question = question_fixture(:true_false)

      # Test correct answer
      correct_answer = %{"is_true" => true}
      assert {:ok, true} = Questions.check_answer_correctness(question.id, correct_answer)

      # Test incorrect answer
      incorrect_answer = %{"is_true" => false}
      assert {:ok, false} = Questions.check_answer_correctness(question.id, incorrect_answer)

      # Test with old format 'selected' (backward compatibility)
      legacy_correct = %{"selected" => true}
      assert {:ok, true} = Questions.check_answer_correctness(question.id, legacy_correct)

      legacy_incorrect = %{"selected" => false}
      assert {:ok, false} = Questions.check_answer_correctness(question.id, legacy_incorrect)
    end

    test "check_answer_correctness/2 validates cloze answers correctly", %{user: _user} do
      # answers: ["Paris", "Europe"]
      question = question_fixture(:cloze)

      # Test correct answer (exact case)
      correct_answer = %{"answers" => ["Paris", "Europe"]}
      assert {:ok, true} = Questions.check_answer_correctness(question.id, correct_answer)

      # Test correct answer (case insensitive)
      case_answer = %{"answers" => ["paris", "EUROPE"]}
      assert {:ok, true} = Questions.check_answer_correctness(question.id, case_answer)

      # Test correct answer (with extra whitespace)
      whitespace_answer = %{"answers" => [" Paris ", " Europe "]}
      assert {:ok, true} = Questions.check_answer_correctness(question.id, whitespace_answer)

      # Test incorrect answer
      incorrect_answer = %{"answers" => ["London", "Europe"]}
      assert {:ok, false} = Questions.check_answer_correctness(question.id, incorrect_answer)

      # Test wrong number of answers
      wrong_count_answer = %{"answers" => ["Paris"]}

      assert {:error, :wrong_number_of_answers} =
               Questions.check_answer_correctness(question.id, wrong_count_answer)

      # Test too many answers
      extra_answers = %{"answers" => ["Paris", "Europe", "France"]}

      assert {:error, :wrong_number_of_answers} =
               Questions.check_answer_correctness(question.id, extra_answers)
    end

    test "check_answer_correctness/2 validates written answers correctly", %{user: _user} do
      question = question_fixture(:written)

      # Written answers always return false (require manual grading)
      answer = %{"text" => "Any written response"}
      assert {:ok, false} = Questions.check_answer_correctness(question.id, answer)

      # Test with legacy format
      legacy_answer = %{"answer_text" => "Legacy format response"}
      assert {:ok, false} = Questions.check_answer_correctness(question.id, legacy_answer)
    end

    test "check_answer_correctness/2 validates EMQ answers correctly", %{user: _user} do
      # matches: [[0, 0], [1, 1], [2, 2]]
      question = question_fixture(:emq)

      # Test correct answer (exact order)
      correct_answer = %{"matches" => [[0, 0], [1, 1], [2, 2]]}
      assert {:ok, true} = Questions.check_answer_correctness(question.id, correct_answer)

      # Test correct answer (different order)
      reordered_answer = %{"matches" => [[2, 2], [0, 0], [1, 1]]}
      assert {:ok, true} = Questions.check_answer_correctness(question.id, reordered_answer)

      # Test incorrect answer
      incorrect_answer = %{"matches" => [[0, 1], [1, 0], [2, 2]]}
      assert {:ok, false} = Questions.check_answer_correctness(question.id, incorrect_answer)

      # Test incomplete answer
      incomplete_answer = %{"matches" => [[0, 0], [1, 1]]}
      assert {:ok, false} = Questions.check_answer_correctness(question.id, incomplete_answer)
    end

    test "check_answer_correctness/2 handles invalid question ID" do
      answer = %{"selected_index" => 0}
      assert {:error, :question_not_found} = Questions.check_answer_correctness(999_999, answer)
    end

    test "check_answer_correctness/2 handles mismatched answer and question types" do
      mcq_question = question_fixture(:mcq_single)

      # Try to answer MCQ with true/false answer
      tf_answer = %{"is_true" => true}

      assert {:error, {:answer_processing_failed, _}} =
               Questions.check_answer_correctness(mcq_question.id, tf_answer)

      # Try to answer MCQ with cloze answer
      cloze_answer = %{"answers" => ["some", "answers"]}

      assert {:error, {:answer_processing_failed, _}} =
               Questions.check_answer_correctness(mcq_question.id, cloze_answer)
    end

    test "check_answer_correctness/2 handles invalid answer format", %{user: _user} do
      question = question_fixture(:mcq_single)

      # Empty answer
      assert {:error, _} = Questions.check_answer_correctness(question.id, %{})

      # Wrong field name
      wrong_field = %{"wrong_field" => "value"}
      assert {:error, _} = Questions.check_answer_correctness(question.id, wrong_field)

      # Invalid data type
      invalid_type = %{"selected_index" => "not_a_number"}
      assert {:error, _} = Questions.check_answer_correctness(question.id, invalid_type)
    end
  end

  describe "delete_user_answer/2" do
    setup do
      user = user_fixture()
      question = question_fixture()
      %{user: user, question: question}
    end

    test "delete_user_answer/2 deletes existing user answer", %{user: user, question: question} do
      # Create an answer
      _answer = answer_fixture(user, question)

      # Verify it exists
      assert Questions.get_user_answer(user.id, question.id) != nil

      # Delete it
      assert {:ok, _} = Questions.delete_user_answer(user.id, question.id)

      # Verify it's gone
      assert Questions.get_user_answer(user.id, question.id) == nil
    end

    test "delete_user_answer/2 returns ok when answer doesn't exist", %{
      user: user,
      question: question
    } do
      # Try to delete non-existent answer
      assert {:ok, :not_found} = Questions.delete_user_answer(user.id, question.id)
    end

    test "delete_user_answer/2 only deletes the specific user's answer", %{
      user: user,
      question: question
    } do
      other_user = user_fixture()

      # Create answers for both users
      _user_answer = answer_fixture(user, question)
      other_answer = answer_fixture(other_user, question)

      # Delete first user's answer
      assert {:ok, _} = Questions.delete_user_answer(user.id, question.id)

      # Verify only the first user's answer was deleted
      assert Questions.get_user_answer(user.id, question.id) == nil
      assert Questions.get_user_answer(other_user.id, question.id) != nil
      assert Questions.get_answer(other_answer.id) != nil
    end

    test "delete_user_answer/2 only deletes the specific question's answer", %{
      user: user,
      question: question
    } do
      other_question = question_fixture()

      # Create answers for both questions
      _answer1 = answer_fixture(user, question)
      answer2 = answer_fixture(user, other_question)

      # Delete answer for first question
      assert {:ok, _} = Questions.delete_user_answer(user.id, question.id)

      # Verify only the first question's answer was deleted
      assert Questions.get_user_answer(user.id, question.id) == nil
      assert Questions.get_user_answer(user.id, other_question.id) != nil
      assert Questions.get_answer(answer2.id) != nil
    end

    test "delete_user_answer/2 works with non-existent user", %{question: question} do
      assert {:ok, :not_found} = Questions.delete_user_answer(999_999, question.id)
    end

    test "delete_user_answer/2 works with non-existent question", %{user: user} do
      assert {:ok, :not_found} = Questions.delete_user_answer(user.id, 999_999)
    end
  end

  describe "modify_question_sets/3" do
    setup do
      user = user_fixture()
      other_user = user_fixture()
      question = question_fixture()

      # Create question sets owned by user
      set1 = question_set_fixture(user, %{title: "Set 1"})
      set2 = question_set_fixture(user, %{title: "Set 2"})
      set3 = question_set_fixture(user, %{title: "Set 3"})

      # Create a set owned by other user
      other_set = question_set_fixture(other_user, %{title: "Other Set"})

      # Add question to set1 initially
      Questions.add_questions_to_set(set1, [question], user.id)

      %{
        user: user,
        other_user: other_user,
        question: question,
        set1: set1,
        set2: set2,
        set3: set3,
        other_set: other_set
      }
    end

    test "modifies question sets according to specifications", %{
      user: user,
      question: question,
      set1: set1,
      set2: set2,
      set3: set3
    } do
      # Initial state: question is in set1 only
      modifications = [
        # Remove from set1
        {set1.id, false},
        # Add to set2
        {set2.id, true},
        # Add to set3
        {set3.id, true}
      ]

      assert {:ok, result} = Questions.modify_question_sets(user.id, question.id, modifications)
      assert result.added_to_sets == 2
      assert result.removed_from_sets == 1
      assert result.total_modified == 3
      assert length(result.modified_sets) == 3

      # Verify the modifications were applied
      current_sets = Questions.get_question_sets_containing_question(question.id)
      assert set1.id not in current_sets
      assert set2.id in current_sets
      assert set3.id in current_sets
    end

    test "handles no-op modifications correctly", %{
      user: user,
      question: question,
      set1: set1,
      set2: set2
    } do
      # Modifications that don't change anything
      modifications = [
        # Already in set1
        {set1.id, true},
        # Already not in set2
        {set2.id, false}
      ]

      assert {:ok, result} = Questions.modify_question_sets(user.id, question.id, modifications)
      assert result.added_to_sets == 0
      assert result.removed_from_sets == 0
      assert result.total_modified == 0
      assert result.modified_sets == []

      # Verify state unchanged
      current_sets = Questions.get_question_sets_containing_question(question.id)
      assert set1.id in current_sets
      assert set2.id not in current_sets
    end

    test "only modifies sets owned by the user", %{
      user: user,
      question: question,
      set1: set1,
      other_set: other_set
    } do
      # Try to modify both owned and non-owned sets
      modifications = [
        # User's set - should work
        {set1.id, false},
        # Other user's set - should be ignored
        {other_set.id, true}
      ]

      assert {:ok, result} = Questions.modify_question_sets(user.id, question.id, modifications)
      assert result.removed_from_sets == 1
      assert result.added_to_sets == 0
      assert result.total_modified == 1

      # Verify only user's set was modified
      current_sets = Questions.get_question_sets_containing_question(question.id)
      assert set1.id not in current_sets
      # Not added because not owned
      assert other_set.id not in current_sets
    end

    test "handles empty modifications list", %{user: user, question: question} do
      assert {:ok, result} = Questions.modify_question_sets(user.id, question.id, [])
      assert result.added_to_sets == 0
      assert result.removed_from_sets == 0
      assert result.total_modified == 0
      assert result.modified_sets == []
    end

    test "handles non-existent question sets gracefully", %{
      user: user,
      question: question,
      set1: set1
    } do
      modifications = [
        # Valid set
        {set1.id, false},
        # Non-existent set
        {999_999, true}
      ]

      # Should still process the valid modification
      assert {:ok, result} = Questions.modify_question_sets(user.id, question.id, modifications)
      assert result.removed_from_sets == 1
      assert result.added_to_sets == 0
      assert result.total_modified == 1
    end

    test "works with question not initially in any sets", %{user: user, set1: set1, set2: set2} do
      # Create a new question not in any sets
      new_question = question_fixture()

      modifications = [
        {set1.id, true},
        {set2.id, true}
      ]

      assert {:ok, result} =
               Questions.modify_question_sets(user.id, new_question.id, modifications)

      assert result.added_to_sets == 2
      assert result.removed_from_sets == 0
      assert result.total_modified == 2

      # Verify question was added to both sets
      current_sets = Questions.get_question_sets_containing_question(new_question.id)
      assert set1.id in current_sets
      assert set2.id in current_sets
    end

    test "returns correct modified_sets information", %{
      user: user,
      question: question,
      set1: set1,
      set2: set2
    } do
      modifications = [
        # Remove
        {set1.id, false},
        # Add
        {set2.id, true}
      ]

      assert {:ok, result} = Questions.modify_question_sets(user.id, question.id, modifications)

      # Check that modified_sets contains the correct maps
      modified_sets_by_id = Enum.group_by(result.modified_sets, & &1.set_id)
      assert Map.get(modified_sets_by_id, set1.id) |> List.first() |> Map.get(:action) == false
      assert Map.get(modified_sets_by_id, set2.id) |> List.first() |> Map.get(:action) == true
    end

    test "handles large number of modifications efficiently", %{user: user, question: question} do
      # Create many sets
      sets =
        Enum.map(1..20, fn i ->
          question_set_fixture(user, %{title: "Set #{i}"})
        end)

      # Add question to all sets
      modifications = Enum.map(sets, fn set -> {set.id, true} end)

      assert {:ok, result} = Questions.modify_question_sets(user.id, question.id, modifications)
      assert result.added_to_sets == 20
      assert result.total_modified == 20

      # Verify all sets contain the question
      current_sets = Questions.get_question_sets_containing_question(question.id)
      set_ids = Enum.map(sets, & &1.id)
      assert length(current_sets) >= 20

      Enum.each(set_ids, fn set_id ->
        assert set_id in current_sets
      end)
    end
  end

  describe "get_owned_question_sets_with_containing_information_for_question/5" do
    setup do
      user = user_fixture()
      other_user = user_fixture()
      question = question_fixture()

      # Create question sets
      set1 = question_set_fixture(user, %{title: "User Set 1", description: "First set"})
      set2 = question_set_fixture(user, %{title: "User Set 2", description: "Second set"})
      set3 = question_set_fixture(user, %{title: "User Set 3", description: "Third set"})
      other_set = question_set_fixture(other_user, %{title: "Other User Set"})

      # Add question to set1 and set3
      Questions.add_questions_to_set(set1, [question], user.id)
      Questions.add_questions_to_set(set3, [question], user.id)

      %{
        user: user,
        other_user: other_user,
        question: question,
        set1: set1,
        set2: set2,
        set3: set3,
        other_set: other_set
      }
    end

    test "returns owned sets with correct containment information", %{
      user: user,
      question: question,
      set1: set1,
      set2: set2,
      set3: set3
    } do
      {results, total_count} =
        Questions.get_owned_question_sets_with_containing_information_for_question(
          user.id,
          question.id
        )

      assert total_count == 3
      assert length(results) == 3

      # Convert to a map for easier testing
      results_map =
        Map.new(results, fn %{question_set: qs, contains_question: contains} ->
          {qs.id, contains}
        end)

      # Contains question
      assert Map.get(results_map, set1.id) == true
      # Doesn't contain question
      assert Map.get(results_map, set2.id) == false
      # Contains question
      assert Map.get(results_map, set3.id) == true
      # Other user's set not included
      refute Map.has_key?(results_map, :other_set)
    end

    test "supports search functionality", %{user: user, question: question} do
      {results, _total} =
        Questions.get_owned_question_sets_with_containing_information_for_question(
          user.id,
          question.id,
          "First"
        )

      assert length(results) == 1
      assert List.first(results).question_set.description == "First set"
    end

    test "supports pagination", %{user: user, question: question} do
      # Test with page size of 2
      {results_page1, total} =
        Questions.get_owned_question_sets_with_containing_information_for_question(
          user.id,
          question.id,
          "",
          1,
          2
        )

      {results_page2, _} =
        Questions.get_owned_question_sets_with_containing_information_for_question(
          user.id,
          question.id,
          "",
          2,
          2
        )

      assert total == 3
      assert length(results_page1) == 2
      assert length(results_page2) == 1
    end

    test "only returns sets owned by the user", %{
      user: user,
      other_user: other_user,
      question: question
    } do
      # Test with user
      {user_results, user_total} =
        Questions.get_owned_question_sets_with_containing_information_for_question(
          user.id,
          question.id
        )

      # Test with other user
      {other_results, other_total} =
        Questions.get_owned_question_sets_with_containing_information_for_question(
          other_user.id,
          question.id
        )

      # User has 3 sets
      assert user_total == 3
      # Other user has 1 set
      assert other_total == 1

      user_set_ids = Enum.map(user_results, fn %{question_set: qs} -> qs.id end)
      other_set_ids = Enum.map(other_results, fn %{question_set: qs} -> qs.id end)

      # No overlap between user's and other user's results
      assert MapSet.disjoint?(MapSet.new(user_set_ids), MapSet.new(other_set_ids))
    end

    test "works correctly when question is not in any sets", %{user: user} do
      new_question = question_fixture()

      {results, total} =
        Questions.get_owned_question_sets_with_containing_information_for_question(
          user.id,
          new_question.id
        )

      assert total == 3
      assert length(results) == 3

      # All should have contains_question = false
      Enum.each(results, fn %{contains_question: contains} ->
        assert contains == false
      end)
    end

    test "handles user with no question sets", %{question: question} do
      user_with_no_sets = user_fixture()

      {results, total} =
        Questions.get_owned_question_sets_with_containing_information_for_question(
          user_with_no_sets.id,
          question.id
        )

      assert total == 0
      assert results == []
    end

    test "preloads associations correctly", %{user: user, question: question} do
      {results, _} =
        Questions.get_owned_question_sets_with_containing_information_for_question(
          user.id,
          question.id
        )

      first_result = List.first(results)
      question_set = first_result.question_set

      # Verify associations are loaded
      assert question_set.tags != %Ecto.Association.NotLoaded{}
      assert question_set.owner != %Ecto.Association.NotLoaded{}
      assert question_set.owner.email != nil
    end
  end

  describe "advanced FTS5 search and bulk operations" do
    alias ZiStudy.Questions.QuestionSet
    alias ZiStudyWeb.Live.QuestionHandlers

    setup do
      user = user_fixture()
      other_user = user_fixture()
      tag1 = tag_fixture(%{name: "math"})
      tag2 = tag_fixture(%{name: "science"})
      set1 = question_set_fixture(user, %{title: "Math Set", is_private: false})
      set2 = question_set_fixture(user, %{title: "Science Set", is_private: false})
      set3 = question_set_fixture(other_user, %{title: "Other Set", is_private: false})
      Questions.add_tags_to_question_set(set1, [tag1.id])
      Questions.add_tags_to_question_set(set2, [tag2.id])

      q1 =
        question_fixture(:mcq_single, %{
          "question_text" => "What is 2 + 2?",
          "question_type" => "mcq_single",
          "difficulty" => "easy"
        })

      q2 =
        question_fixture(:mcq_single, %{
          "question_text" => "What is H2O?",
          "question_type" => "mcq_single",
          "difficulty" => "medium"
        })

      q3 =
        question_fixture(:mcq_single, %{
          "question_text" => "What is the primordial gas in the universe?",
          "question_type" => "mcq_single",
          "difficulty" => "hard"
        })

      # Ensure FTS5 table has entries for our test questions
      ZiStudy.Repo.query!(
        """
        INSERT OR REPLACE INTO questions_fts(question_id, question_text, options, answers, explanation, retention_aid, instructions, premises)
        SELECT
          id,
          json_extract(data, '$.question_text'),
          json_extract(data, '$.options'),
          json_extract(data, '$.answers'),
          json_extract(data, '$.explanation'),
          json_extract(data, '$.retention_aid'),
          json_extract(data, '$.instructions'),
          json_extract(data, '$.premises')
        FROM questions WHERE id IN (?, ?, ?)
        """,
        [q1.id, q2.id, q3.id]
      )

      Questions.add_questions_to_set(set1, [q1])
      Questions.add_questions_to_set(set2, [q2])

      %{
        user: user,
        other_user: other_user,
        set1: set1,
        set2: set2,
        set3: set3,
        q1: q1,
        q2: q2,
        q3: q3,
        tag1: tag1,
        tag2: tag2
      }
    end

    test "search_questions_advanced/2 returns relevant results and highlights", %{q1: q1, q2: _q2} do
      # We're using a direct query to avoid quoting issues in the test
      {results, next_cursor} = Questions.search_questions_advanced("2", limit: 10)
      assert Enum.any?(results, fn r -> r.question.id == q1.id end)
      assert is_nil(next_cursor) or is_integer(next_cursor)
      assert Enum.all?(results, fn r -> is_map(r.highlights) end)
    end

    test "search_questions_advanced/2 supports difficulty filters", %{q2: q2} do
      {results, _} = Questions.search_questions_advanced("*", difficulties: ["medium"], limit: 10)
      assert Enum.any?(results, fn r -> r.question.id == q2.id end)
    end

    test "search_questions_advanced/2 supports type filters", %{q1: q1} do
      {results, _} =
        Questions.search_questions_advanced("*", question_types: ["mcq_single"], limit: 10)

      assert Enum.any?(results, fn r -> r.question.id == q1.id end)
    end

    test "bulk_add_questions_to_set/3 only allows owner to add", %{
      user: user,
      other_user: other_user,
      set1: set1,
      q2: q2
    } do
      # Owner can add
      assert {:ok, _} = Questions.bulk_add_questions_to_set(user.id, [q2.id], set1.id)
      # Non-owner cannot add
      assert {:error, :unauthorized} =
               Questions.bulk_add_questions_to_set(other_user.id, [q2.id], set1.id)
    end

    test "modify_question_sets/3 adds and removes correctly", %{
      user: user,
      set1: set1,
      set2: set2,
      q1: q1
    } do
      # Remove from set1, add to set2
      mods = [
        %{"set_id" => Integer.to_string(set1.id), "should_contain" => false},
        %{"set_id" => Integer.to_string(set2.id), "should_contain" => true}
      ]

      {:ok, result} =
        Questions.modify_question_sets(
          user.id,
          q1.id,
          Enum.map(mods, fn %{"set_id" => id, "should_contain" => sc} ->
            {String.to_integer(id), sc}
          end)
        )

      assert is_integer(result.added_to_sets)
      assert is_integer(result.removed_from_sets)
    end

    test "quick_create_question_set/2 creates a private set", %{user: user} do
      {:ok, set} = Questions.quick_create_question_set(user, "Quick Set")
      assert set.title == "Quick Set"
      assert set.is_private == true
      assert set.owner_id == user.id
    end

    test "search_questions_advanced/2 handles special characters gracefully", %{q1: q1, q2: q2} do
      # Test query that used to cause errors
      assert {:ok, {results, _}} =
               Code.eval_string("ZiStudy.Questions.search_questions_advanced(\"2+2\", limit: 10)")
               |> then(fn {res, _} -> {:ok, res} end)

      assert Enum.any?(results, &(&1.question.id == q1.id))

      # Test with other special characters
      assert {:ok, {res_slash, _}} =
               Code.eval_string(
                 "ZiStudy.Questions.search_questions_advanced(\"H2O/water\", limit: 10)"
               )
               |> then(fn {res, _} -> {:ok, res} end)

      # This won't find anything, but it shouldn't crash
      assert length(res_slash) == 0

      assert {:ok, {res_star, _}} =
               Code.eval_string(
                 "ZiStudy.Questions.search_questions_advanced(\"H2O*\", limit: 10)"
               )
               |> then(fn {res, _} -> {:ok, res} end)

      assert Enum.any?(res_star, &(&1.question.id == q2.id))
    end

    test "search_questions_advanced/2 with '*' query searches all", %{q1: q1, q2: q2} do
      {results, _} = Questions.search_questions_advanced("*", limit: 10)
      assert length(results) >= 2
      assert Enum.any?(results, &(&1.question.id == q1.id))
      assert Enum.any?(results, &(&1.question.id == q2.id))
    end

    test "search_questions_advanced/2 handles prefix search sensitively", %{q3: q3} do
      {results, _} = Questions.search_questions_advanced("prim", limit: 10)
      assert Enum.any?(results, &(&1.question.id == q3.id))
    end

    test "search_questions_advanced/2 handles problematic special characters without FTS errors",
         _context do
      # Test various special characters that previously caused FTS5 syntax errors
      special_chars_tests = [
        # asterisk - should trigger search all
        "*",
        # backslash
        "\\",
        # forward slash
        "/",
        # plus sign
        "+",
        # expression with plus
        "2+2",
        # mixed alphanumeric with slash
        "H2O/water",
        # asterisk within term
        "test*query",
        # quoted text
        "\"quoted\"",
        # parentheses
        "(parentheses)",
        # square brackets
        "[brackets]",
        # ampersand
        "a & b",
        # pipe
        "a | b",
        # question mark
        "question?",
        # exclamation mark
        "test!",
        # caret
        "a^b",
        # dollar sign
        "a$b",
        # tilde
        "a~b",
        # curly braces
        "{braces}",
        # colon
        ":",
        # semicolon
        ";"
      ]

      # Each of these should not cause an Exqlite.Error with FTS5 syntax
      Enum.each(special_chars_tests, fn char ->
        assert {results, _cursor} = Questions.search_questions_advanced(char, limit: 10)
        # Results can be empty, but no exception should be raised
        assert is_list(results)
      end)
    end

    test "search_questions_advanced/2 handles search scope correctly without FTS errors", %{
      q3: q3
    } do
      # Test searching only in question_text scope - should find "primordial"
      {results, _} =
        Questions.search_questions_advanced("primordial",
          search_scope: [:question_text],
          limit: 10
        )

      assert Enum.any?(results, &(&1.question.id == q3.id))

      # Test searching in non-existent scope for this question - should find nothing
      {results, _} =
        Questions.search_questions_advanced("primordial", search_scope: [:options], limit: 10)

      refute Enum.any?(results, &(&1.question.id == q3.id))

      # Test multiple scope search - should work without OR syntax errors
      {results, _} =
        Questions.search_questions_advanced("primordial",
          search_scope: [:question_text, :options],
          limit: 10
        )

      assert Enum.any?(results, &(&1.question.id == q3.id))
    end
  end

  describe "QuestionHandlers DTO helpers" do
    alias ZiStudyWeb.Live.ActiveLearning.QuestionHandlers

    test "owner_to_dto/1 returns correct map" do
      assert QuestionHandlers.owner_to_dto(%{email: "a@b.com"}) == %{email: "a@b.com"}
      assert QuestionHandlers.owner_to_dto(nil) == nil
    end

    test "get_tag_dto/1 returns correct map" do
      assert QuestionHandlers.get_tag_dto(%{id: 1, name: "foo"}) == %{id: 1, name: "foo"}
    end

    test "get_question_dto/1 returns correct map" do
      now = DateTime.utc_now()

      q = %{
        id: 1,
        data: %{},
        difficulty: "easy",
        type: "mcq_single",
        inserted_at: now,
        updated_at: now
      }

      dto = QuestionHandlers.get_question_dto(q)
      assert dto.id == 1
      assert dto.difficulty == "easy"
      assert dto.type == "mcq_single"
      assert dto.inserted_at == now
    end

    test "question_set_to_accessible_dto/2 returns correct map" do
      now = DateTime.utc_now()

      set = %{
        id: 1,
        title: "T",
        description: "D",
        is_private: false,
        owner_id: 2,
        owner: %{email: "a@b.com"},
        tags: [%{id: 1, name: "foo"}],
        inserted_at: now,
        updated_at: now
      }

      dto = QuestionHandlers.question_set_to_accessible_dto(set, 2)
      assert dto.is_owned == true
      assert dto.owner == %{email: "a@b.com"}
      assert Enum.at(dto.tags, 0).name == "foo"
    end

    test "question_set_to_dto/1 returns correct map" do
      now = DateTime.utc_now()

      set = %{
        id: 1,
        title: "T",
        description: "D",
        is_private: false,
        owner: %{email: "a@b.com"},
        tags: [%{id: 1, name: "foo"}],
        questions: [%{id: 1}],
        inserted_at: now,
        updated_at: now
      }

      dto = QuestionHandlers.question_set_to_dto(set)
      assert dto.num_questions == 1
      assert dto.owner == %{email: "a@b.com"}
    end
  end
end
