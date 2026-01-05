class Product < ApplicationRecord
  ALLOWED_DOMAINS = [
    "amazon.com",
    "amazon.co.uk",
    "amazon.ca",
    "target.com",
    "walmart.com"
  ].freeze

  has_many :price_alerts, dependent: :destroy
  has_many :users, through: :price_alerts
  has_many :price_histories, dependent: :destroy

  validates :url, presence: true, uniqueness: true
  validates :current_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :check_status, inclusion: { in: %w[pending success blocked error] }

  validate :url_must_be_from_allowed_domain

  scope :needs_check, -> { where("last_checked_at IS NULL OR last_checked_at < ?", 6.hours.ago) }
  scope :with_active_alerts, -> { joins(:price_alerts).where(price_alerts: { active: true }).distinct }

  def stale?
    last_checked_at.nil? || last_checked_at < 6.hours.ago
  end

  def lowest_price
    price_histories.minimum(:price) || current_price
  end

  def highest_price
    price_histories.maximum(:price) || current_price
  end

  def average_price(days: 30)
    PriceHistory.average_price(self, days: days)
  end

  def price_trend(days: 7)
    PriceHistory.trend_for_product(self, days: days)
  end

  def price_change_percentage
    return 0 unless price_histories.any?

    oldest = price_histories.order(:recorded_at).first.price
    current = current_price || 0

    return 0 if oldest.zero?

    ((current - oldest) / oldest * 100).round(2)
  end

  private

  def url_must_be_from_allowed_domain
    return if url.blank?

    begin
      uri = URI.parse(url)

      unless %w[http https].include?(uri.scheme)
        errors.add(:url, "must be a valid HTTP or HTTPS URL")
        return
      end

      host = uri.host&.downcase

      if host == "localhost" || host == "127.0.0.1"
        unless Rails.env.development? || Rails.env.test?
          errors.add(:url, "localhost URLs are only allowed in development")
        end
        return
      end

      if Rails.env.production? && private_network?(host)
        errors.add(:url, "cannot be a private network address")
        return
      end

      allowed = ALLOWED_DOMAINS.any? do |allowed_domain|
        host == allowed_domain || host&.end_with?(".#{allowed_domain}")
      end

      unless allowed
        errors.add(:url, "must be from an allowed retailer: #{ALLOWED_DOMAINS.join(', ')}")
      end
    rescue URI::InvalidURIError
      errors.add(:url, "is not a valid URL")
    end
  end

  def private_network?(host)
    return false if host.nil?

    blocked_patterns = [
      /^10\./,
      /^172\.(1[6-9]|2[0-9]|3[0-1])\./,
      /^192\.168\./,
      /^169\.254\./
    ]

    blocked_patterns.any? { |pattern| host =~ pattern }
  end
end
