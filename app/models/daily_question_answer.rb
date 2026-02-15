class DailyQuestionAnswer < ApplicationRecord
  belongs_to :user
  belongs_to :quiz_question
  belongs_to :chosen_book_list_item, class_name: 'BookListItem'

  validates :answer_date, presence: true, uniqueness: { scope: :user_id }
end
