# frozen_string_literal: true

class CreateQuizQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_questions do |t|
      t.text :question_text, null: false
      t.references :book_list, null: false, foreign_key: true
      t.references :correct_book_list_item, null: false, foreign_key: { to_table: :book_list_items }
      t.integer :position, default: 0, null: false

      t.timestamps
    end
  end
end
