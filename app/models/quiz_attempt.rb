# frozen_string_literal: true

class QuizAttempt < ApplicationRecord
  belongs_to :user
  belongs_to :book_list
  has_many :quiz_challenges, dependent: :destroy

  validates :correct_count, :total_count, presence: true
  validates :correct_count, numericality: { greater_than_or_equal_to: 0 }
  validates :total_count, numericality: { greater_than: 0 }
end
