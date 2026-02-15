class AddProgressPercentToBookAssignments < ActiveRecord::Migration[8.0]
  def change
    add_column :book_assignments, :progress_percent, :integer, default: 0, null: false
  end
end
