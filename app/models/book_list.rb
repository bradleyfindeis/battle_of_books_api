# frozen_string_literal: true

class BookList < ApplicationRecord
  has_many :book_list_items, -> { order(:position) }, dependent: :destroy
  has_many :quiz_questions, dependent: :destroy
  has_many :quiz_attempts, dependent: :destroy
  has_many :teams, dependent: :nullify
  validates :name, presence: true
end
