# frozen_string_literal: true

class CreateBookLists < ActiveRecord::Migration[8.0]
  def change
    create_table :book_lists do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
