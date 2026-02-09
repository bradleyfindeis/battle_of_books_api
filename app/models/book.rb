class Book < ApplicationRecord
  belongs_to :team
  has_many :book_assignments, dependent: :destroy
  has_many :assigned_users, through: :book_assignments, source: :user
  validates :title, presence: true
end
