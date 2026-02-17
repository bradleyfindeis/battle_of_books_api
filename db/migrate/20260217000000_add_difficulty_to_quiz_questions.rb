# frozen_string_literal: true

class AddDifficultyToQuizQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :quiz_questions, :difficulty, :integer, default: 0, null: false
    add_index :quiz_questions, [:book_list_id, :difficulty]

    add_column :quiz_matches, :difficulty, :string
  end
end
