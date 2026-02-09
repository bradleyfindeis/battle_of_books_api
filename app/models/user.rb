class User < ApplicationRecord
  belongs_to :team
  has_many :book_assignments, dependent: :destroy
  has_many :quiz_attempts, dependent: :destroy
  has_many :quiz_challenges, dependent: :destroy
  has_many :quiz_matches_as_challenger, class_name: 'QuizMatch', foreign_key: :challenger_id, dependent: :destroy
  has_many :quiz_matches_as_opponent, class_name: 'QuizMatch', foreign_key: :opponent_id, dependent: :nullify
  has_many :assigned_books, through: :book_assignments, source: :book
  has_many :assignments_given, class_name: 'BookAssignment', foreign_key: :assigned_by_id
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
end
