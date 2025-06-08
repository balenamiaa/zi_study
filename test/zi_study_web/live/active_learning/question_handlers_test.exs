defmodule ZiStudyWeb.Live.ActiveLearning.QuestionHandlersTest do
  use ZiStudy.DataCase

  import ZiStudy.Fixtures

  alias ZiStudy.Questions
  alias ZiStudyWeb.Live.ActiveLearning.QuestionHandlers

  describe "handle_answer_question/3" do
    test "handles MCQ single answers correctly" do
      user = user_fixture()
      question = question_fixture(:mcq_single)

      # MCQ answers need to be maps with option indices
      answer_data = %{"selected_index" => 0}

      {:ok, answer_dto, _meta} =
        QuestionHandlers.handle_answer_question(
          to_string(question.id),
          answer_data,
          user
        )

      assert answer_dto.question_id == question.id
      assert is_integer(answer_dto.is_correct)
    end

    test "handles written answers correctly" do
      user = user_fixture()
      question = question_fixture(:written)

      {:ok, answer_dto, _meta} =
        QuestionHandlers.handle_answer_question(
          to_string(question.id),
          %{"answer_text" => "My answer"},
          user
        )

      assert answer_dto.question_id == question.id
      # Not evaluated
      assert answer_dto.is_correct == 2
    end

    test "returns error for non-existent question" do
      user = user_fixture()

      {:error, message} =
        QuestionHandlers.handle_answer_question(
          "999999",
          "answer",
          user
        )

      assert message == "Question not found"
    end
  end

  describe "handle_modify_question_sets/3" do
    test "adds and removes questions from sets correctly" do
      user = user_fixture()
      question = question_fixture()
      set1 = question_set_fixture(user)
      set2 = question_set_fixture(user)

      modifications = [
        %{"set_id" => to_string(set1.id), "should_contain" => true},
        %{"set_id" => to_string(set2.id), "should_contain" => false}
      ]

      {:ok, result} =
        QuestionHandlers.handle_modify_question_sets(
          to_string(question.id),
          modifications,
          user
        )

      assert Map.has_key?(result, :modified_sets)
    end
  end

  describe "handle_add_question_to_sets/3" do
    test "adds question to multiple question sets" do
      user = user_fixture()
      question = question_fixture()
      set1 = question_set_fixture(user)
      set2 = question_set_fixture(user)

      {:ok, result} =
        QuestionHandlers.handle_add_question_to_sets(
          to_string(question.id),
          [to_string(set1.id), to_string(set2.id)],
          user
        )

      assert Map.has_key?(result, :count)
    end

    test "handles adding to non-owned question sets" do
      user1 = user_fixture()
      user2 = user_fixture()
      question = question_fixture()
      owned_set = question_set_fixture(user1)
      not_owned_set = question_set_fixture(user2)

      {:ok, result} =
        QuestionHandlers.handle_add_question_to_sets(
          to_string(question.id),
          [to_string(owned_set.id), to_string(not_owned_set.id)],
          user1
        )

      # Should only add to owned set
      assert Map.has_key?(result, :count)
    end
  end

  describe "handle_bulk_add_questions_to_sets/3" do
    test "adds multiple questions to multiple sets" do
      user = user_fixture()
      question1 = question_fixture()
      question2 = question_fixture()
      set1 = question_set_fixture(user)
      set2 = question_set_fixture(user)

      {:ok, result} =
        QuestionHandlers.handle_bulk_add_questions_to_sets(
          user.id,
          [question1.id, question2.id],
          [set1.id, set2.id]
        )

      assert result.added_to_sets == 2
      assert result.total_questions == 2
    end

    test "returns error when no owned question sets found" do
      user1 = user_fixture()
      user2 = user_fixture()
      question = question_fixture()
      not_owned_set = question_set_fixture(user2)

      {:error, message} =
        QuestionHandlers.handle_bulk_add_questions_to_sets(
          user1.id,
          [question.id],
          [not_owned_set.id]
        )

      assert message == "No owned question sets found"
    end
  end

  describe "handle_update_question_set/4" do
    test "updates question set title" do
      user = user_fixture()
      question_set = question_set_fixture(user)

      {:ok, updated_set} =
        QuestionHandlers.handle_update_question_set(
          question_set.id,
          "title",
          "New Title",
          user
        )

      assert updated_set.title == "New Title"
    end

    test "returns error for unauthorized user" do
      user1 = user_fixture()
      user2 = user_fixture()
      question_set = question_set_fixture(user1)

      {:error, message} =
        QuestionHandlers.handle_update_question_set(
          question_set.id,
          "title",
          "New Title",
          user2
        )

      assert message == "You don't have permission to edit this set"
    end

    test "returns error for non-existent question set" do
      user = user_fixture()

      {:error, message} =
        QuestionHandlers.handle_update_question_set(
          999_999,
          "title",
          "New Title",
          user
        )

      assert message == "Question set not found"
    end
  end

  describe "handle_load_tags/1" do
    test "loads and formats all tags" do
      # Create tags with specific names we can test for
      _tag1 = Questions.create_tag(%{name: "science"}) |> elem(1)
      _tag2 = Questions.create_tag(%{name: "math"}) |> elem(1)

      tags = QuestionHandlers.handle_load_tags("")

      assert length(tags) >= 2
      tag_names = Enum.map(tags, & &1.name)
      assert "science" in tag_names
      assert "math" in tag_names
    end

    test "filters tags by search query" do
      Questions.create_tag(%{name: "science"})
      Questions.create_tag(%{name: "mathematics"})
      Questions.create_tag(%{name: "history"})

      science_tags = QuestionHandlers.handle_load_tags("sci")
      math_tags = QuestionHandlers.handle_load_tags("math")

      science_names = Enum.map(science_tags, & &1.name)
      math_names = Enum.map(math_tags, & &1.name)

      assert "science" in science_names
      refute "mathematics" in science_names
      refute "history" in science_names

      assert "mathematics" in math_names
      refute "science" in math_names
    end
  end

  describe "handle_create_tag/1" do
    test "creates new tag with valid name" do
      {:ok, tag_dto} = QuestionHandlers.handle_create_tag("new-tag")

      assert tag_dto.name == "new-tag"
      assert tag_dto.id != nil
    end

    test "returns error for invalid tag name" do
      {:error, message} = QuestionHandlers.handle_create_tag(nil)

      assert message == "Failed to create tag"
    end

    test "returns error for empty tag name" do
      {:error, message} = QuestionHandlers.handle_create_tag("")

      assert message == "Failed to create tag"
    end
  end

  describe "handle_add_tags_to_question_set/3" do
    test "adds tags to question set" do
      user = user_fixture()
      question_set = question_set_fixture(user)
      tag1 = Questions.create_tag(%{name: "science"}) |> elem(1)
      tag2 = Questions.create_tag(%{name: "math"}) |> elem(1)

      {:ok, updated_set} =
        QuestionHandlers.handle_add_tags_to_question_set(
          to_string(question_set.id),
          [to_string(tag1.id), to_string(tag2.id)],
          user
        )

      updated_set_with_tags = Questions.get_question_set(updated_set.id) |> Repo.preload(:tags)
      tag_names = Enum.map(updated_set_with_tags.tags, & &1.name)
      assert "science" in tag_names
      assert "math" in tag_names
    end

    test "returns error for unauthorized user" do
      user1 = user_fixture()
      user2 = user_fixture()
      question_set = question_set_fixture(user1)
      tag = Questions.create_tag(%{name: "test"}) |> elem(1)

      {:error, message} =
        QuestionHandlers.handle_add_tags_to_question_set(
          to_string(question_set.id),
          [to_string(tag.id)],
          user2
        )

      assert message == "You don't have permission to edit this set"
    end
  end

  describe "handle_remove_tags_from_question_set/3" do
    test "removes tags from question set" do
      user = user_fixture()
      question_set = question_set_fixture(user)
      tag1 = Questions.create_tag(%{name: "science"}) |> elem(1)
      tag2 = Questions.create_tag(%{name: "math"}) |> elem(1)

      # Add tags first
      Questions.add_tags_to_question_set(question_set, [tag1.name, tag2.name])

      # Remove one tag
      {:ok, updated_set} =
        QuestionHandlers.handle_remove_tags_from_question_set(
          to_string(question_set.id),
          [to_string(tag1.id)],
          user
        )

      updated_set_with_tags = Questions.get_question_set(updated_set.id) |> Repo.preload(:tags)
      tag_names = Enum.map(updated_set_with_tags.tags, & &1.name)
      refute "science" in tag_names
      assert "math" in tag_names
    end

    test "returns error for unauthorized user" do
      user1 = user_fixture()
      user2 = user_fixture()
      question_set = question_set_fixture(user1)
      tag = Questions.create_tag(%{name: "test"}) |> elem(1)

      {:error, message} =
        QuestionHandlers.handle_remove_tags_from_question_set(
          to_string(question_set.id),
          [to_string(tag.id)],
          user2
        )

      assert message == "You don't have permission to edit this set"
    end
  end

  describe "get_question_set_with_answers/2" do
    test "returns question set with full data" do
      user = user_fixture()
      question_set = question_set_fixture(user)
      question1 = question_fixture()
      question2 = question_fixture()

      # Add questions to set
      Questions.add_questions_to_set(question_set, [question1, question2])

      # Create some answers
      answer_fixture(user, question1)

      result = QuestionHandlers.get_question_set_with_answers(question_set.id, user.id)

      assert result.id == question_set.id
      assert Map.has_key?(result, :questions)
      assert Map.has_key?(result, :answers)
      assert Map.has_key?(result, :stats)
      assert length(result.questions) == 2
      assert length(result.answers) == 1
    end
  end

  describe "DTO helper functions" do
    test "owner_to_dto/1 returns correct map" do
      owner = %{email: "test@example.com", name: "Test User"}

      result = QuestionHandlers.owner_to_dto(owner)

      assert result == %{email: "test@example.com"}
    end

    test "owner_to_dto/1 handles nil" do
      result = QuestionHandlers.owner_to_dto(nil)

      assert result == nil
    end

    test "get_tag_dto/1 returns correct map" do
      tag = %{id: 1, name: "science"}

      result = QuestionHandlers.get_tag_dto(tag)

      assert result == %{id: 1, name: "science"}
    end

    test "get_question_dto/1 returns formatted question" do
      now = DateTime.utc_now()

      question = %{
        id: 1,
        data: %{"question_text" => "Test?"},
        difficulty: "easy",
        type: "mcq_single",
        inserted_at: now,
        updated_at: now
      }

      result = QuestionHandlers.get_question_dto(question)

      assert result.id == 1
      assert result.difficulty == "easy"
      assert result.type == "mcq_single"
      assert result.inserted_at == now
      assert result.updated_at == now
      assert Map.has_key?(result, :data)
    end

    test "question_set_to_dto/1 returns formatted question set" do
      now = DateTime.utc_now()

      question_set = %{
        id: 1,
        title: "Test Set",
        description: "Test Description",
        is_private: false,
        owner: %{email: "owner@test.com"},
        tags: [%{id: 1, name: "science"}],
        questions: [%{id: 1}, %{id: 2}],
        inserted_at: now,
        updated_at: now
      }

      result = QuestionHandlers.question_set_to_dto(question_set)

      assert result.id == 1
      assert result.title == "Test Set"
      assert result.num_questions == 2
      assert result.owner == %{email: "owner@test.com"}
      assert length(result.tags) == 1
    end

    test "question_set_to_accessible_dto/2 marks ownership correctly" do
      now = DateTime.utc_now()

      question_set = %{
        id: 1,
        title: "Test Set",
        description: "Test Description",
        is_private: false,
        owner_id: 123,
        owner: %{email: "owner@test.com"},
        tags: [],
        inserted_at: now,
        updated_at: now
      }

      # User is owner
      owned_result = QuestionHandlers.question_set_to_accessible_dto(question_set, 123)
      assert owned_result.is_owned == true

      # User is not owner
      not_owned_result = QuestionHandlers.question_set_to_accessible_dto(question_set, 456)
      assert not_owned_result.is_owned == false
    end
  end

  describe "streaming and metadata functions" do
    setup do
      user = user_fixture()

      question_set =
        question_set_fixture(user, %{title: "Test Set", description: "Test Description"})

      # Create 15 questions for testing streaming
      questions =
        Enum.map(1..15, fn i ->
          question_fixture(:mcq_single, %{"question_text" => "Question #{i}"})
        end)

      Questions.add_questions_to_set(question_set, questions)

      # Create some answers for the user
      answer_fixture(user, Enum.at(questions, 0))
      answer_fixture(user, Enum.at(questions, 1))

      %{user: user, question_set: question_set, questions: questions}
    end

    test "get_question_set_metadata/2 returns metadata without questions", %{
      user: user,
      question_set: question_set
    } do
      metadata = QuestionHandlers.get_question_set_metadata(question_set.id, user.id)

      assert metadata.id == question_set.id
      assert metadata.title == "Test Set"
      assert metadata.description == "Test Description"
      # Should be empty for metadata
      assert metadata.questions == []
      # Should be empty for metadata
      assert metadata.answers == []
      assert Map.has_key?(metadata, :stats)
      assert Map.has_key?(metadata, :owner)
      assert Map.has_key?(metadata, :tags)
    end

    test "get_initial_questions_chunk/3 returns first chunk with streaming state", %{
      user: user,
      question_set: question_set
    } do
      {chunk_data, streaming_state} =
        QuestionHandlers.get_initial_questions_chunk(question_set.id, user.id, 5)

      # Check chunk data
      assert Map.has_key?(chunk_data, :questions)
      assert Map.has_key?(chunk_data, :answers)
      assert length(chunk_data.questions) == 5
      # Only 2 questions have answers
      assert length(chunk_data.answers) == 2

      # Check streaming state
      assert streaming_state.loaded_count == 5
      assert streaming_state.total_count == 15
      assert streaming_state.has_more == true
      assert streaming_state.is_streaming == false
    end

    test "get_initial_questions_chunk/3 handles empty question set", %{user: user} do
      empty_set = question_set_fixture(user)

      {chunk_data, streaming_state} =
        QuestionHandlers.get_initial_questions_chunk(empty_set.id, user.id, 10)

      assert chunk_data.questions == []
      assert chunk_data.answers == []
      assert streaming_state.loaded_count == 0
      assert streaming_state.total_count == 0
      assert streaming_state.has_more == false
    end

    test "get_questions_chunk/4 returns subsequent chunks", %{
      user: user,
      question_set: question_set
    } do
      # Get second chunk (offset 5, size 5)
      {chunk_data, streaming_state} =
        QuestionHandlers.get_questions_chunk(question_set.id, user.id, 5, 5)

      assert length(chunk_data.questions) == 5
      # 5 + 5
      assert streaming_state.loaded_count == 10
      assert streaming_state.total_count == 15
      assert streaming_state.has_more == true
      # Should continue streaming
      assert streaming_state.is_streaming == true
    end

    test "answer_to_dto_minimal/1 returns minimal answer structure" do
      user = user_fixture()
      question = question_fixture()
      answer = answer_fixture(user, question)

      # Convert to the minimal format that would be returned by the database
      minimal_answer = %{
        id: answer.id,
        question_id: answer.question_id,
        data: answer.data,
        is_correct: answer.is_correct,
        user_id: answer.user_id,
        inserted_at: answer.inserted_at,
        updated_at: answer.updated_at
      }

      result = QuestionHandlers.answer_to_dto_minimal(minimal_answer)

      assert result.id == answer.id
      assert result.question_id == answer.question_id
      assert result.data == answer.data
      assert result.is_correct == answer.is_correct

      # Should not have preloaded associations
      refute Map.has_key?(result, :user)
      refute Map.has_key?(result, :question)
    end
  end

  describe "streaming integration scenarios" do
    test "complete streaming flow simulates real usage" do
      user = user_fixture()
      question_set = question_set_fixture(user)

      # Create 25 questions to test multiple chunks
      questions = Enum.map(1..25, fn _i -> question_fixture() end)
      Questions.add_questions_to_set(question_set, questions)

      # Simulate the complete flow

      # 1. Get metadata first (like page load)
      metadata = QuestionHandlers.get_question_set_metadata(question_set.id, user.id)
      assert metadata.questions == []

      # 2. Get initial chunk (SSR)
      {initial_chunk, state1} =
        QuestionHandlers.get_initial_questions_chunk(question_set.id, user.id, 10)

      assert length(initial_chunk.questions) == 10
      assert state1.loaded_count == 10
      assert state1.has_more == true

      # 3. Stream second chunk
      {chunk2, state2} = QuestionHandlers.get_questions_chunk(question_set.id, user.id, 10, 10)
      assert length(chunk2.questions) == 10
      assert state2.loaded_count == 20
      assert state2.has_more == true

      # 4. Stream final chunk
      {chunk3, state3} = QuestionHandlers.get_questions_chunk(question_set.id, user.id, 20, 10)
      # Only 5 remaining
      assert length(chunk3.questions) == 5
      assert state3.loaded_count == 25
      assert state3.has_more == false

      # Verify we got all questions across chunks
      total_questions =
        length(initial_chunk.questions) + length(chunk2.questions) + length(chunk3.questions)

      assert total_questions == 25
    end
  end
end
