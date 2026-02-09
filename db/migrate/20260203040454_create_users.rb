class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :username
      t.string :email
      t.string :pin_code_digest
      t.boolean :pin_reset_required
      t.integer :role
      t.references :team, null: false, foreign_key: true

      t.timestamps
    end
  end
end
