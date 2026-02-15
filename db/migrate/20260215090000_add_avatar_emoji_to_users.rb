class AddAvatarEmojiToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :avatar_emoji, :string, limit: 10
  end
end
