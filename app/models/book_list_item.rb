# frozen_string_literal: true

class BookListItem < ApplicationRecord
  belongs_to :book_list
  has_many :quiz_questions, foreign_key: :correct_book_list_item_id, dependent: :destroy
  has_many :quiz_challenges, foreign_key: :chosen_book_list_item_id, dependent: :destroy
  validates :title, presence: true
end
