class CreateBookAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :book_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.integer :assigned_by_id
      t.integer :status
      t.text :progress_notes

      t.timestamps
    end

    add_foreign_key :book_assignments, :users, column: :assigned_by_id
    add_index :book_assignments, [:user_id, :book_id], unique: true
  end
end
