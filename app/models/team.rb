class Team < ApplicationRecord
  belongs_to :invite_code, optional: true
  belongs_to :book_list, optional: true
  has_many :users, dependent: :destroy
  has_many :books, dependent: :destroy
  has_many :quiz_matches, dependent: :destroy
  has_many :teammates, -> { where(role: :teammate) }, class_name: 'User'
  has_one :team_lead, -> { where(role: :team_lead) }, class_name: 'User'
  validates :name, presence: true

  # If team has books but no book_list_id (e.g. chose list before we stored it), try to match
  # to a BookList and set book_list_id so quiz and stats work.
  def resolve_book_list!
    return if book_list_id.present?
    return if books.empty?

    team_pairs = books.map { |b| [b.title.to_s.strip, (b.author || '').to_s.strip] }.sort
    BookList.includes(:book_list_items).find_each do |list|
      list_pairs = list.book_list_items.map { |i| [i.title.to_s.strip, (i.author || '').to_s.strip] }.sort
      if team_pairs == list_pairs
        update_column(:book_list_id, list.id)
        break
      end
    end
  end
end
