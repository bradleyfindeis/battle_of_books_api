class CreateRefreshTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :refresh_tokens do |t|
      t.string :token_digest, null: false, index: { unique: true }
      t.references :user, null: true, foreign_key: true
      t.references :admin, null: true, foreign_key: true
      t.datetime :expires_at, null: false
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :refresh_tokens, :expires_at
  end
end
