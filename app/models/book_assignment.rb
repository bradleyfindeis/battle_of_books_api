class BookAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :book
  belongs_to :assigned_by, class_name: 'User'
  enum :status, { assigned: 0, in_progress: 1, completed: 2 }
  validates :user_id, uniqueness: { scope: :book_id, message: 'already has this book assigned' }
  validate :same_team
  attribute :status, default: :assigned

  private
  def same_team
    return unless user && book
    errors.add(:book, 'must belong to the same team as the user') unless user.team_id == book.team_id
  end
end
