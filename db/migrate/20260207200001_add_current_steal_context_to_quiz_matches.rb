# frozen_string_literal: true

class AddCurrentStealContextToQuizMatches < ActiveRecord::Migration[8.0]
  def change
    add_column :quiz_matches, :current_steal_context, :jsonb
  end
end
