# frozen_string_literal: true

class AddPhaseEnteredAtToQuizMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :quiz_matches, :phase_entered_at, :datetime
  end
end
