# frozen_string_literal: true

class QuizChallenge < ApplicationRecord
  belongs_to :user
  belongs_to :quiz_attempt
  belongs_to :quiz_question
  belongs_to :chosen_book_list_item, class_name: 'BookListItem'

  validates :justification, presence: true
  validates :quiz_attempt_id, uniqueness: { scope: :quiz_question_id, message: 'already has a challenge for this question' }
  validate :attempt_belongs_to_user
  validate :question_belongs_to_attempt_book_list

  private

  def attempt_belongs_to_user
    return unless quiz_attempt && user

    return if quiz_attempt.user_id == user_id

    errors.add(:quiz_attempt, 'must belong to you')
  end

  def question_belongs_to_attempt_book_list
    return unless quiz_attempt && quiz_question

    return if quiz_question.book_list_id == quiz_attempt.book_list_id

    errors.add(:quiz_question, 'must belong to the same book list as the attempt')
  end
end
