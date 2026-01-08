class PriceAlert < ApplicationRecord
  belongs_to :user
  belongs_to :product

  validates :target_price, presence: true, numericality: { greater_than: 0 }
  validates :user_id, uniqueness: { scope: :product_id, message: "User already has an alert for this product" }
  validate :check_user_alert_limit, on: :create
  validate :target_price_must_be_lower_than_current_price, if: :validate_target_price?

  scope :active, -> { where(active: true) }
  scope :triggered, -> {
    joins(:product).where("products.current_price <= price_alerts.target_price AND products.current_price IS NOT NULL")
  }

  def price_dropped?
    product.current_price.present? && product.current_price <= target_price
  end

  def validate_target_price?
    product&.current_price.present? &&
    (new_record? || will_save_change_to_target_price?)
  end

  def should_notify?
    price_dropped? && last_notified_at.nil?
  end

  private

  def check_user_alert_limit
    return if user.blank?

    if user.price_alerts.count >= User::MAX_ALERTS_PER_USER
      errors.add(:base, "You can only have #{User::MAX_ALERTS_PER_USER} active price alerts")
    end
  end

  def target_price_must_be_lower_than_current_price
    return unless product&.current_price && target_price

    if target_price >= product.current_price
      errors.add(:target_price, "must be lower than current price ($#{product.current_price})")
    end
  end
end
