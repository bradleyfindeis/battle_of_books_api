# frozen_string_literal: true

class CreateBookListItems < ActiveRecord::Migration[8.0]
  def change
    create_table :book_list_items do |t|
      t.references :book_list, null: false, foreign_key: true
      t.string :title, null: false
      t.string :author
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :book_list_items, [:book_list_id, :position]
  end
end
