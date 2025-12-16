class Product < ApplicationRecord
  has_many :price_alerts, dependent: :destroy
  has_many :users, through: :price_alerts

  validates :url, presence: true, uniqueness: true
  validates :name, presence: true
  validates :current_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :check_status, inclusion: { in: %w[pending success blocked error] }

  scope :needs_check, -> { where("last_checked_at IS NULL OR last_checked_at < ?", 6.hours.ago) }
  scope :with_active_alerts, -> { joins(:price_alerts).where(price_alerts: { active: true }).distinct }

  def stale?
    last_checked_at.nil? || last_checked_at < 6.hours.ago
  end
end
