class Admin < ApplicationRecord
  has_secure_password
  has_many :invite_codes, dependent: :destroy
  has_many :refresh_tokens, dependent: :destroy
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
end
