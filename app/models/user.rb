class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :price_alerts, dependent: :destroy
  has_many :products, through: :price_alerts

  validates :username, presence: true
  validates :email_address, presence: true,
                            uniqueness: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :role, inclusion: { in: %w[user admin] }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  after_initialize :set_default_role, if: :new_record?

  private

  def set_default_role
    self.role ||= "user"
  end
end
