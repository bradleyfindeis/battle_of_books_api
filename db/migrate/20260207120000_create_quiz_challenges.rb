# frozen_string_literal: true

class CreateQuizChallenges < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_challenges do |t|
      t.references :user, null: false, foreign_key: true
      t.references :quiz_attempt, null: false, foreign_key: true
      t.references :quiz_question, null: false, foreign_key: true
      t.references :chosen_book_list_item, null: false, foreign_key: { to_table: :book_list_items }
      t.string :page_number
      t.text :justification, null: false
      t.boolean :upheld, null: false, default: false

      t.timestamps
    end

    add_index :quiz_challenges, %i[quiz_attempt_id quiz_question_id], unique: true,
              name: "index_quiz_challenges_on_attempt_and_question"
  end
end
