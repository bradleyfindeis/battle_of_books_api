# frozen_string_literal: true

class QuizQuestion < ApplicationRecord
  belongs_to :book_list
  belongs_to :correct_book_list_item, class_name: 'BookListItem'
  has_many :quiz_challenges, dependent: :destroy

  validates :question_text, presence: true
  validates :correct_book_list_item, presence: true
  validate :correct_item_belongs_to_same_list

  private

  def correct_item_belongs_to_same_list
    return if correct_book_list_item.blank? || book_list.blank?

    return if correct_book_list_item.book_list_id == book_list_id

    errors.add(:correct_book_list_item, 'must belong to the same book list')
  end
end
