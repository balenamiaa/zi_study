defmodule ZiStudy.Repo.Migrations.CreateQuestionsTable do
  use Ecto.Migration

  def change do
    create table(:questions) do
      add :data, :jsonb, null: false
      add :difficulty, :string
      add :type, :string
      timestamps(type: :utc_datetime)
    end

    create table(:tags) do
      add :name, :string, null: false
      timestamps(type: :utc_datetime)
    end

    create table(:question_sets) do
      add :title, :string, null: false
      add :description, :text
      add :owner_id, references(:users, on_delete: :nothing)
      add :is_private, :boolean, default: false
      timestamps(type: :utc_datetime)
    end

    create table(:question_set_tags) do
      add :question_set_id, references(:question_sets, on_delete: :delete_all)
      add :tag_id, references(:tags, on_delete: :delete_all)
    end

    create table(:question_set_questions) do
      add :question_set_id, references(:question_sets, on_delete: :delete_all)
      add :question_id, references(:questions, on_delete: :delete_all)
      add :position, :integer, null: false
    end

    create table(:answers) do
      add :data, :jsonb, null: false
      add :is_correct, :integer, null: false, default: 2
      add :user_id, references(:users, on_delete: :delete_all)
      add :question_id, references(:questions, on_delete: :delete_all)
      timestamps(type: :utc_datetime)
    end

    create index(:answers, [:user_id])
    create index(:answers, [:question_id])
    create index(:answers, [:is_correct])

    create index(:question_set_tags, [:question_set_id])
    create index(:question_set_tags, [:tag_id])
    create unique_index(:question_set_tags, [:question_set_id, :tag_id])

    create index(:question_set_questions, [:question_set_id])
    create index(:question_set_questions, [:question_id])
    create unique_index(:question_set_questions, [:question_set_id, :position])

    create unique_index(:tags, [:name])
    create index(:questions, [:difficulty])
    create index(:questions, [:type])
  end
end
