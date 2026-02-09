# frozen_string_literal: true

class CreateQuizMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_matches do |t|
      t.references :challenger, null: false, foreign_key: { to_table: :users }
      t.references :invited_opponent, null: false, foreign_key: { to_table: :users }
      t.references :opponent, null: true, foreign_key: { to_table: :users }
      t.references :team, null: false, foreign_key: true
      t.references :book_list, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :phase, null: false, default: 0
      t.integer :challenger_score, null: false, default: 0
      t.integer :opponent_score, null: false, default: 0
      t.integer :current_question_index, null: false, default: 0
      t.references :first_responder, null: true, foreign_key: { to_table: :users }
      t.jsonb :questions_payload, null: false, default: []

      t.timestamps
    end

    add_index :quiz_matches, [:challenger_id, :status]
    add_index :quiz_matches, [:opponent_id, :status]
    add_index :quiz_matches, [:team_id, :status]
  end
end
