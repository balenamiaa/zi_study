defmodule ZiStudy.Questions.Answer do
  use Ecto.Schema
  import Ecto.Changeset

  @correct_enum [0, 1, 2]

  schema "answers" do
    field :data, :map
    field :is_correct, :integer, default: 2
    belongs_to :user, ZiStudy.Accounts.User
    belongs_to :question, ZiStudy.Questions.Question
    timestamps()
  end

  @doc false
  def changeset(answer, attrs) do
    answer
    |> cast(attrs, [:data, :is_correct, :user_id, :question_id])
    |> validate_required([:data, :user_id, :question_id])
    |> validate_inclusion(:is_correct, @correct_enum)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:question_id)
  end
end
