class User < ApplicationRecord
  belongs_to :team
  has_many :book_assignments, dependent: :destroy
  has_many :quiz_attempts, dependent: :destroy
  has_many :quiz_challenges, dependent: :destroy
  has_many :quiz_matches_as_challenger, class_name: 'QuizMatch', foreign_key: :challenger_id, dependent: :destroy
  has_many :quiz_matches_as_opponent, class_name: 'QuizMatch', foreign_key: :opponent_id, dependent: :nullify
  has_many :assigned_books, through: :book_assignments, source: :book
  has_many :assignments_given, class_name: 'BookAssignment', foreign_key: :assigned_by_id
  has_many :activity_days, dependent: :destroy
  has_many :daily_question_answers, dependent: :destroy
  enum :role, { teammate: 0, team_lead: 1 }
  validates :username, presence: true, uniqueness: { scope: :team_id }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, if: :team_lead?
  has_secure_password :pin_code, validations: false
  attribute :pin_reset_required, default: true

  def generate_pin!
    new_pin = rand(1000..9999).to_s.rjust(4, '0')
    update!(pin_code: new_pin, pin_reset_required: true)
    new_pin
  end

  # Record that this user was active today. Safe to call multiple times per day.
  def log_activity!
    activity_days.find_or_create_by(activity_date: Date.current)
  rescue ActiveRecord::RecordNotUnique
    # race condition; another request already inserted it — that's fine
  end

  # Calculate current streak (consecutive days ending today or yesterday).
  def current_streak
    dates = activity_days.order(activity_date: :desc).pluck(:activity_date)
    return 0 if dates.empty?

    today = Date.current
    # Streak can start from today or yesterday (so you don't lose it mid-day)
    start = dates.first == today ? today : (dates.first == today - 1 ? today - 1 : nil)
    return 0 unless start

    streak = 0
    expected = start
    dates.each do |d|
      if d == expected
        streak += 1
        expected -= 1
      elsif d < expected
        break
      end
    end
    streak
  end
end
