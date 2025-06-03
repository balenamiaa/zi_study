# ZiStudy Question Management System

This document provides an overview of the ZiStudy Question Management System, its core components, and the JSON format expected for importing questions.

## System Overview

The primary purpose of this system is to manage educational questions, organize them into question sets, and associate them with tags. It provides a robust backend for creating, retrieving, updating, and deleting these entities, along with a powerful import mechanism for batch-creating questions from a JSON-formatted file.

### Core Entities:

*   **Questions**: The fundamental unit, representing a single question of various types (e.g., Multiple Choice, True/False, Written).
*   **Question Sets**: Collections of questions, which can be owned by users or be public. They can have titles, descriptions, and associated tags.
*   **Tags**: Keywords or labels that can be associated with question sets for categorization and searching.

### Core Modules:

*   `ZiStudy.Questions`: The main context module. It exposes the public API for all operations related to questions, question sets, and tags. This includes CRUD operations and the import functionality.
*   `ZiStudy.QuestionsOps`: A supporting namespace for question-related operations:
    *   `Import`: Defines the Elixir structs that represent the raw data for different question types as they are imported from JSON.
    *   `Converter`: Handles the conversion of these raw import structs into a standardized `Processed.Question` struct, which is then used to create the actual `Question` Ecto schema.
    *   `JsonSerializer`: Manages the deserialization of JSON strings into the appropriate `Import` structs.
    *   `Processed`: Defines the Elixir structs for standardized question content after initial processing and before database insertion.

## JSON Import Format

To import questions, provide a JSON array where each element is an object representing a single question. Each question object must have a `question_type` field, which determines the expected structure for the rest of its fields.

### Common Fields (Applicable to all question types):

*   `temp_id` (String | Atom): A temporary identifier for the question, primarily used during import to link answers/options to their parent question if needed (e.g., in EMQs or complex Cloze questions). Can be a string or an atom.
*   `question_type` (String): Specifies the type of the question. Valid values are:
    *   `"mcq-single"`
    *   `"mcq-multi"`
    *   `"written"`
    *   `"true-false"`
    *   `"cloze"`
    *   `"emq"`
*   `difficulty` (String): A string indicating the difficulty level (e.g., "easy", "medium", "hard").
*   `question_text` (String): The main text/prompt of the question.
*   `retention_aid` (String, Optional): Text or hints to aid retention or recall.
*   `explanation` (String, Optional): An explanation for the question or its answer.

### Question Type Specific Fields:

Below are the specific fields required for each `question_type`.

#### 1. Multiple Choice - Single Answer (`mcq-single`)

*   `options` (Array of Objects): A list of possible answers.
    *   Each option object: `{"temp_id": "opt1", "text": "Option text"}`
*   `correct_option_temp_id` (String | Atom): The `temp_id` of the correct option from the `options` array.

**Example:**
```json
{
  "temp_id": "q1_mcq_single",
  "question_type": "mcq-single",
  "difficulty": "medium",
  "question_text": "What is the capital of France?",
  "options": [
    {"temp_id": "opt_a", "text": "Berlin"},
    {"temp_id": "opt_b", "text": "Paris"},
    {"temp_id": "opt_c", "text": "London"}
  ],
  "correct_option_temp_id": "opt_b",
  "retention_aid": "Think about major European capitals",
  "explanation": "Paris is the capital of France."
}
```

#### 2. Multiple Choice - Multiple Answers (`mcq-multi`)

*   `options` (Array of Objects): A list of possible answers.
    *   Each option object: `{"temp_id": "opt1", "text": "Option text"}`
*   `correct_option_temp_ids` (Array of Strings/Atoms): A list of `temp_id`s for all correct options from the `options` array.

**Example:**
```json
{
  "temp_id": "q2_mcq_multi",
  "question_type": "mcq-multi",
  "difficulty": "hard",
  "question_text": "Which of the following are primary colors?",
  "options": [
    {"temp_id": "opt_r", "text": "Red"},
    {"temp_id": "opt_g", "text": "Green"},
    {"temp_id": "opt_b", "text": "Blue"},
    {"temp_id": "opt_y", "text": "Yellow"}
  ],
  "correct_option_temp_ids": ["opt_r", "opt_b", "opt_y"],
  "retention_aid": "Remember the color wheel basics",
  "explanation": "Red, yellow, and blue are primary colors. Green is secondary."
}
```

#### 3. Written Answer (`written`)

*   No additional specific fields are strictly required beyond the common fields. The answer is expected to be free-form text provided by the user during an attempt, not defined at import.

**Example:**
```json
{
  "temp_id": "q3_written",
  "question_type": "written",
  "difficulty": "easy",
  "question_text": "Explain the concept of photosynthesis in your own words.",
  "retention_aid": "Think about how plants make food from sunlight",
  "explanation": "Photosynthesis is the process used by plants to convert light energy into chemical energy."
}
```

#### 4. True/False (`true-false`)

*   `is_true` (Boolean): Indicates if the correct answer to the `question_text` is true or false.

**Example:**
```json
{
  "temp_id": "q4_tf",
  "question_type": "true-false",
  "difficulty": "easy",
  "question_text": "The Earth is flat.",
  "is_true": false,
  "retention_aid": "Consider what we know about Earth's shape from space",
  "explanation": "The Earth is an oblate spheroid."
}
```

#### 5. Cloze (Fill in the Blanks) (`cloze`)

*   `question_text` (String): The text containing blanks with hints. Blanks are represented by placeholders in the format `{{c#::hint}}` where `c#` is the blank number (c1, c2, etc.) and `hint` is optional text to help the user.
*   `answers` (Array of Strings): A list of correct answers corresponding to each blank in order. The first answer corresponds to `{{c1::}}`, the second to `{{c2::}}`, and so on.

**Important Notes:**
- The `question_text` contains hints inline (e.g., `{{c1::hint1}}`), but the actual correct answers are stored separately in the `answers` array
- Each `{{c#::hint}}` placeholder corresponds to the answer at position `(# - 1)` in the `answers` array
- Hints in the question text are optional and can be omitted: `{{c1::}}` is valid

**Example:**
```json
{
  "temp_id": "q5_cloze",
  "question_type": "cloze",
  "difficulty": "medium",
  "question_text": "In {{c1::major conflicts}} and {{c2::diplomatic negotiations}}, there is a {{c3::mediator role}} that is very {{c4::crucial}} to a {{c5::peaceful resolution}}.",
  "answers": ["wars", "treaties", "role", "important", "solution"],
  "retention_aid": "Think about conflict resolution",
  "explanation": "This describes the process of international diplomacy."
}
```

**Usage in Code:**
```elixir
ZiStudy.Questions.create_question(%ZiStudy.QuestionsOps.Processed.Question.Cloze{
  question_text:
    "In {{c1::hint1}} and {{c2::hint2}}, there is a {{c3::hint3}} that is very {{c4::hint4}} to a {{c5::hint5}}.",
  difficulty: "5",
  retention_aid: "Some retention aid",
  answers: ["answer1", "answer2", "answer3", "answer4", "answer5"]
})
```

#### 6. Extended Matching Question (`emq`)

*   `lead_in_statement` (String): An introductory statement or scenario for the EMQ.
*   `answer_options` (Array of Objects): A list of possible answer choices that can be applied to multiple items/stems.
    *   Each option object: `{"temp_id": "ao1", "text": "Answer Option 1"}`
*   `items` (Array of Objects): A list of stems or questions to be matched with the `answer_options`.
    *   Each item object: `{"temp_id": "item1", "text": "Stem/Item text 1", "correct_option_temp_id": "ao2"}` (where `correct_option_temp_id` refers to a `temp_id` from `answer_options`).

**Example:**
```json
{
  "temp_id": "q6_emq",
  "question_type": "emq",
  "difficulty": "hard",
  "question_text": "Match the description to the correct drug class.",
  "lead_in_statement": "For each patient presentation below, select the most appropriate drug class from the list.",
  "answer_options": [
    {"temp_id": "ao_ace", "text": "ACE Inhibitor"},
    {"temp_id": "ao_beta", "text": "Beta Blocker"},
    {"temp_id": "ao_ca", "text": "Calcium Channel Blocker"}
  ],
  "items": [
    {
      "temp_id": "item_htn_cough", 
      "text": "Patient with hypertension develops a persistent dry cough.", 
      "correct_option_temp_id": "ao_ace"
    },
    {
      "temp_id": "item_angina_brady", 
      "text": "Patient with angina and bradycardia.", 
      "correct_option_temp_id": "ao_beta"
    }
  ],
  "retention_aid": "Remember drug side effects and contraindications",
  "explanation": "ACE inhibitors can cause a dry cough. Beta blockers are used for angina but can cause bradycardia."
}
```
