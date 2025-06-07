defmodule ZiStudy.Repo.Migrations.AddQuestionsFts5 do
  use Ecto.Migration

  def up do
    # Create FTS5 virtual table for full-text search
    execute """
    CREATE VIRTUAL TABLE questions_fts USING fts5(
      question_id UNINDEXED,
      question_text,
      options,
      answers,
      correct_answer,
      explanation,
      retention_aid,
      instructions,
      premises,
      difficulty,
      question_type,
      tokenize = 'porter unicode61'
    );
    """

    # Create trigger to keep FTS table in sync on insert
    execute """
    CREATE TRIGGER questions_fts_insert AFTER INSERT ON questions
    BEGIN
      INSERT INTO questions_fts(
        question_id,
        question_text,
        options,
        answers,
        correct_answer,
        explanation,
        retention_aid,
        instructions,
        premises,
        difficulty,
        question_type
      )
      VALUES (
        NEW.id,
        json_extract(NEW.data, '$.question_text'),
        COALESCE(
          (SELECT json_group_array(value) FROM json_each(json_extract(NEW.data, '$.options'))),
          ''
        ),
        COALESCE(
          (SELECT json_group_array(value) FROM json_each(json_extract(NEW.data, '$.answers'))),
          json_extract(NEW.data, '$.correct_answer')
        ),
        json_extract(NEW.data, '$.correct_answer'),
        json_extract(NEW.data, '$.explanation'),
        json_extract(NEW.data, '$.retention_aid'),
        json_extract(NEW.data, '$.instructions'),
        COALESCE(
          (SELECT json_group_array(value) FROM json_each(json_extract(NEW.data, '$.premises'))),
          ''
        ),
        json_extract(NEW.data, '$.difficulty'),
        json_extract(NEW.data, '$.question_type')
      );
    END;
    """

    # Create trigger to keep FTS table in sync on update
    execute """
    CREATE TRIGGER questions_fts_update AFTER UPDATE ON questions
    BEGIN
      DELETE FROM questions_fts WHERE question_id = OLD.id;
      INSERT INTO questions_fts(
        question_id,
        question_text,
        options,
        answers,
        correct_answer,
        explanation,
        retention_aid,
        instructions,
        premises,
        difficulty,
        question_type
      )
      VALUES (
        NEW.id,
        json_extract(NEW.data, '$.question_text'),
        COALESCE(
          (SELECT json_group_array(value) FROM json_each(json_extract(NEW.data, '$.options'))),
          ''
        ),
        COALESCE(
          (SELECT json_group_array(value) FROM json_each(json_extract(NEW.data, '$.answers'))),
          json_extract(NEW.data, '$.correct_answer')
        ),
        json_extract(NEW.data, '$.correct_answer'),
        json_extract(NEW.data, '$.explanation'),
        json_extract(NEW.data, '$.retention_aid'),
        json_extract(NEW.data, '$.instructions'),
        COALESCE(
          (SELECT json_group_array(value) FROM json_each(json_extract(NEW.data, '$.premises'))),
          ''
        ),
        json_extract(NEW.data, '$.difficulty'),
        json_extract(NEW.data, '$.question_type')
      );
    END;
    """

    # Create trigger to keep FTS table in sync on delete
    execute """
    CREATE TRIGGER questions_fts_delete AFTER DELETE ON questions
    BEGIN
      DELETE FROM questions_fts WHERE question_id = OLD.id;
    END;
    """

    # Populate FTS table with existing data
    execute """
    INSERT INTO questions_fts(
      question_id,
      question_text,
      options,
      answers,
      correct_answer,
      explanation,
      retention_aid,
      instructions,
      premises,
      difficulty,
      question_type
    )
    SELECT
      id,
      json_extract(data, '$.question_text'),
      COALESCE(
        (SELECT json_group_array(value) FROM json_each(json_extract(data, '$.options'))),
        ''
      ),
      COALESCE(
        (SELECT json_group_array(value) FROM json_each(json_extract(data, '$.answers'))),
        json_extract(data, '$.correct_answer')
      ),
      json_extract(data, '$.correct_answer'),
      json_extract(data, '$.explanation'),
      json_extract(data, '$.retention_aid'),
      json_extract(data, '$.instructions'),
      COALESCE(
        (SELECT json_group_array(value) FROM json_each(json_extract(data, '$.premises'))),
        ''
      ),
      json_extract(data, '$.difficulty'),
      json_extract(data, '$.question_type')
    FROM questions;
    """

    # Create indexes for better performance
    create_if_not_exists index(:questions, :difficulty)
    create_if_not_exists index(:questions, :type)
  end

  def down do
    # Drop triggers
    execute "DROP TRIGGER IF EXISTS questions_fts_insert;"
    execute "DROP TRIGGER IF EXISTS questions_fts_update;"
    execute "DROP TRIGGER IF EXISTS questions_fts_delete;"

    # Drop FTS table
    execute "DROP TABLE IF EXISTS questions_fts;"

    # Drop indexes
    drop_if_exists index(:questions, :difficulty)
    drop_if_exists index(:questions, :type)
  end
end
