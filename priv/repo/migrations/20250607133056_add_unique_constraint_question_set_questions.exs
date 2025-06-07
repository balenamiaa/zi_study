defmodule ZiStudy.Repo.Migrations.AddUniqueConstraintQuestionSetQuestions do
  use Ecto.Migration

  def up do
    # First, remove any duplicate question-set relationships
    # Keep the one with the earliest position for each question in each set
    execute """
    DELETE FROM question_set_questions
    WHERE id NOT IN (
      SELECT MIN(id)
      FROM question_set_questions
      GROUP BY question_set_id, question_id
    )
    """

    # Add unique constraint to prevent duplicate questions in the same set
    create unique_index(:question_set_questions, [:question_set_id, :question_id])
  end

  def down do
    drop index(:question_set_questions, [:question_set_id, :question_id])
  end
end
