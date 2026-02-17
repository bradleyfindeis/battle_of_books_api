class RefreshToken < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :admin, optional: true

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true
  validate :must_have_user_or_admin

  scope :active, -> { where(revoked_at: nil).where('expires_at > ?', Time.current) }

  def expired?
    expires_at < Time.current
  end

  def revoked?
    revoked_at.present?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def self.generate_for_user(user)
    raw_token = SecureRandom.urlsafe_base64(32)
    digest = Digest::SHA256.hexdigest(raw_token)
    create!(token_digest: digest, user: user, expires_at: 30.days.from_now)
    raw_token
  end

  def self.generate_for_admin(admin)
    raw_token = SecureRandom.urlsafe_base64(32)
    digest = Digest::SHA256.hexdigest(raw_token)
    create!(token_digest: digest, admin: admin, expires_at: 30.days.from_now)
    raw_token
  end

  def self.find_by_raw_token(raw_token)
    return nil unless raw_token.present?

    digest = Digest::SHA256.hexdigest(raw_token)
    active.find_by(token_digest: digest)
  end

  private

  def must_have_user_or_admin
    errors.add(:base, 'Must belong to either a user or an admin') if user_id.blank? && admin_id.blank?
  end
end
