class User < ApplicationRecord
  MAX_ALERTS_PER_USER = 5

  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :price_alerts, dependent: :destroy
  has_many :products, through: :price_alerts

  validates :username, presence: true, uniqueness: true
  validates :email_address, presence: true,
                            uniqueness: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password,
    length: { minimum: 8 },
    format: {
      with: /\A(?=.*[a-zA-Z])(?=.*\d).*\z/,
      message: "must include at least one letter and one number"
    },
    if: -> { password.present? }

  validates :role, inclusion: { in: %w[user admin] }

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  after_initialize :set_default_role, if: :new_record?

  private

  def set_default_role
    self.role ||= "user"
  end
end
