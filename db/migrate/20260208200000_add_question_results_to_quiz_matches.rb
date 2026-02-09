# frozen_string_literal: true

class AddQuestionResultsToQuizMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :quiz_matches, :question_results, :jsonb, default: [], null: false
  end
end
