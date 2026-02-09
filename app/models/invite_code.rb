class InviteCode < ApplicationRecord
  belongs_to :admin
  has_many :teams, dependent: :nullify

  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true

  before_validation :generate_code, on: :create
  before_validation :upcase_code

  attribute :uses_count, default: 0
  attribute :active, default: true

  scope :available, -> { 
    where(active: true).where('expires_at IS NULL OR expires_at > ?', Time.current) 
  }

  def available?
    return false unless active?
    return false if expires_at.present? && expires_at < Time.current
    return false if max_uses.present? && uses_count >= max_uses
    true
  end

  def use!
    increment!(:uses_count)
  end

  private

  def generate_code
    self.code ||= SecureRandom.alphanumeric(8).upcase
  end

  def upcase_code
    self.code = code&.upcase
  end
end
