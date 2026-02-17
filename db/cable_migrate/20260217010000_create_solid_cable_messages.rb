# frozen_string_literal: true

class CreateSolidCableMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :solid_cable_messages do |t|
      t.text :channel, null: false
      t.binary :payload, null: false, limit: 536_870_912
      t.datetime :created_at, null: false
      t.index [:channel, :created_at]
      t.index :created_at
    end
  end
end
