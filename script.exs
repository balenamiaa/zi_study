alias ZiStudy.Questions

json_string = File.read!("priv/static/questions/extensive_surgery_set_00.json")

{:ok, tags} =
  Enum.reduce_while(
    ["Surgery", "Stage 4", "Stage 5", "Stage 6", "Final Exam", "Endblock Exam", "Moodle"],
    {:ok, []},
    fn tag, {:ok, acc} ->
      {:ok, tag} = Questions.create_tag(%{name: tag})
      {:cont, {:ok, [tag | acc]}}
    end
  )

{:ok, new_set} =
  Questions.create_question_set_ownerless(%{
    title: "Extensive Surgery Set 00",
    description:
      "A cumulative set of questions from past final exams, endblock exams, moodle, and other sources from HMU. Spanning from Stage 4 to Stage 6.",
    tags: tags
  })

# ZiStudy.Repo.delete_all(ZiStudy.Questions.Question)

Questions.update_question_set(new_set |> ZiStudy.Repo.preload(:tags), %{
  tags: tags
})

{:ok, resp} = Questions.import_questions_from_json(json_string, nil, new_set.id)

actual_questions = Questions.get_question_set_questions_with_positions(new_set.id)
all_questions = Questions.list_questions()
