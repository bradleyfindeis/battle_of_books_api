class CreateInviteCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :invite_codes do |t|
      t.string :code
      t.string :name
      t.integer :max_uses
      t.integer :uses_count
      t.datetime :expires_at
      t.boolean :active
      t.references :admin, null: false, foreign_key: true

      t.timestamps
    end
    add_index :invite_codes, :code, unique: true
  end
end
