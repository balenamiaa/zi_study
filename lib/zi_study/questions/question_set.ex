defmodule ZiStudy.Questions.QuestionSet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "question_sets" do
    field :title, :string
    field :description, :string
    field :is_private, :boolean, default: false
    belongs_to :owner, ZiStudy.Accounts.User

    many_to_many :tags, ZiStudy.Questions.Tag,
      join_through: "question_set_tags",
      on_replace: :delete

    many_to_many :questions, ZiStudy.Questions.Question,
      join_through: "question_set_questions",
      join_keys: [question_set_id: :id, question_id: :id]

    timestamps()
  end

  @doc false
  def changeset(question_set, attrs) do
    question_set
    |> cast(attrs, [:title, :description, :owner_id, :is_private])
    |> validate_required([:title])
    |> foreign_key_constraint(:owner_id)
  end
end
