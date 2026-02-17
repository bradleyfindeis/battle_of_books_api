# frozen_string_literal: true

class AddChannelHashToSolidCableMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :solid_cable_messages, :channel_hash, :integer, limit: 8, null: false, default: 0
    add_index :solid_cable_messages, :channel_hash
  end
end
