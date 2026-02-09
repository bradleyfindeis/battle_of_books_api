# frozen_string_literal: true

class QuizMatch < ApplicationRecord
  QUESTIONS_COUNT = 20
  POINTS_PER_CORRECT = 2
  POINTS_PARTIAL = 1 # title-only (first responder) or author-only steal (second responder)

  belongs_to :challenger, class_name: 'User'
  belongs_to :invited_opponent, class_name: 'User'
  belongs_to :opponent, class_name: 'User', optional: true
  belongs_to :team
  belongs_to :book_list

  enum :status, { pending: 0, in_progress: 1, completed: 2, cancelled: 3 }, prefix: :status
  enum :phase, {
    waiting_opponent: 0,
    question_show: 1,
    first_responder_answered: 2,
    second_responder_can_answer: 3,
    between_questions: 4,
    completed: 5
  }, prefix: :phase

  validates :challenger_score, :opponent_score, numericality: { greater_than_or_equal_to: 0 }
  validates :current_question_index, numericality: { greater_than_or_equal_to: 0, less_than: QUESTIONS_COUNT },
                                    unless: -> { status_completed? }
  validate :invited_opponent_same_team
  validate :opponent_same_team, if: -> { opponent_id.present? }
  validate :questions_payload_structure

  scope :for_user, ->(user) {
    where(challenger_id: user.id).or(where(opponent_id: user.id)).or(where(invited_opponent_id: user.id))
  }
  scope :pending_for_opponent, ->(user) { status_pending.where(opponent_id: nil).where(invited_opponent_id: user.id) }

  def participant?(user)
    challenger_id == user.id || opponent_id == user.id || (status_pending? && invited_opponent_id == user.id)
  end

  def opponent_user
    opponent || (status_pending? ? invited_opponent : nil)
  end

  def current_question_data
    return nil if questions_payload.blank? || current_question_index >= questions_payload.size

    questions_payload[current_question_index]
  end

  def first_responder_for_current_question
    data = current_question_data
    return nil unless data && data['first_responder_id']

    User.find_by(id: data['first_responder_id'])
  end

  def second_responder_for_current_question
    first = first_responder_for_current_question
    return nil unless first
    return nil unless opponent_id? # need both players in game

    first.id == challenger_id ? opponent : challenger
  end

  def allowed_responder_id
    case phase
    when 'question_show' then current_question_data&.dig('first_responder_id')
    when 'second_responder_can_answer' then second_responder_for_current_question&.id
    else nil
    end
  end

  def can_answer?(user)
    allowed_responder_id == user.id
  end

  private

  def invited_opponent_same_team
    return unless invited_opponent && team_id.present?

    errors.add(:invited_opponent, 'must be on the same team') unless invited_opponent.team_id == team_id
  end

  def opponent_same_team
    return unless opponent && team_id.present?

    errors.add(:opponent, 'must be on the same team') unless opponent.team_id == team_id
  end

  def questions_payload_structure
    return if questions_payload.blank?

    unless questions_payload.is_a?(Array) && questions_payload.size == QUESTIONS_COUNT
      errors.add(:questions_payload, "must be an array of #{QUESTIONS_COUNT} question entries")
      return
    end

    questions_payload.each_with_index do |entry, i|
      unless entry.is_a?(Hash) && entry['quiz_question_id'].present? && entry['first_responder_id'].present?
        errors.add(:questions_payload, "entry #{i} must have quiz_question_id and first_responder_id")
        break
      end
    end
  end
end
