# frozen_string_literal: true

class CreateQuizAttempts < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_attempts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book_list, null: false, foreign_key: true
      t.integer :correct_count, null: false
      t.integer :total_count, null: false

      t.timestamps
    end

    add_index :quiz_attempts, [:user_id, :book_list_id]
  end
end
