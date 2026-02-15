# frozen_string_literal: true

class ActivityDay < ApplicationRecord
  belongs_to :user

  validates :activity_date, presence: true
  validates :user_id, uniqueness: { scope: :activity_date }
end
