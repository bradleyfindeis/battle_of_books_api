# frozen_string_literal: true

class AddBookListIdToTeams < ActiveRecord::Migration[8.0]
  def change
    add_reference :teams, :book_list, null: true, foreign_key: true
  end
end
