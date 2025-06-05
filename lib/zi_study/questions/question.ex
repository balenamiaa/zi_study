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
    |> validate_question_data()
    |> put_difficulty_and_type()
  end

  defp validate_question_data(changeset) do
    case get_change(changeset, :data) do
      nil ->
        changeset

      data ->
        question_type = Map.get(data, "question_type") || Map.get(data, :question_type)

        # EMQ questions use 'instructions' instead of 'question_text'
        text_field =
          case question_type do
            "emq" -> Map.get(data, "instructions") || Map.get(data, :instructions)
            _ -> Map.get(data, "question_text") || Map.get(data, :question_text)
          end

        changeset =
          if is_nil(text_field) or text_field == "" do
            field_name = if question_type == "emq", do: "instructions", else: "question_text"
            add_error(changeset, :data, "#{field_name} is required")
          else
            changeset
          end

        if is_nil(question_type) do
          add_error(changeset, :data, "question_type is required")
        else
          changeset
        end
    end
  end

  defp put_difficulty_and_type(changeset) do
    case get_change(changeset, :data) do
      nil ->
        changeset

      data ->
        difficulty = Map.get(data, "difficulty") || Map.get(data, :difficulty)

        type =
          Map.get(data, "question_type") || Map.get(data, :question_type) || Map.get(data, :type)

        changeset
        |> put_change(:difficulty, difficulty)
        |> put_change(:type, type)
    end
  end
end
