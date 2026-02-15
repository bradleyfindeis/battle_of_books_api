class CreateActivityDays < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_days do |t|
      t.references :user, null: false, foreign_key: true
      t.date :activity_date, null: false
      t.timestamps
    end

    add_index :activity_days, [:user_id, :activity_date], unique: true
  end
end
