defmodule ZiStudy.Questions.Question do
  use Ecto.Schema
  import Ecto.Changeset

  schema "questions" do
    field :data, :map
    field :difficulty, :string
    field :type, :string

    many_to_many :question_sets, ZiStudy.Questions.QuestionSet,
      join_through: "question_set_questions"

    has_many :answers, ZiStudy.Questions.Answer
    timestamps()
  end

  @doc false
  def changeset(question, attrs) do
    question
    |> cast(attrs, [:data])
    |> validate_required([:data])
    |> put_difficulty_and_type()
  end

  defp put_difficulty_and_type(changeset) do
    case get_change(changeset, :data) do
      nil ->
        changeset

      data ->
        difficulty = Map.get(data, "difficulty") || Map.get(data, :difficulty)
        type = Map.get(data, "question_type") || Map.get(data, :type)

        changeset
        |> put_change(:difficulty, difficulty)
        |> put_change(:type, type)
    end
  end
end
