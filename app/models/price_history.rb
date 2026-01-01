class PriceHistory < ApplicationRecord
  belongs_to :product

  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :recorded_at, presence: true

  scope :recent, -> { order(recorded_at: :desc) }
  scope :for_product, ->(product_id) { where(product_id: product_id) }
  scope :between_dates, ->(start_date, end_date) { where(recorded_at: start_date..end_date) }

  def self.trend_for_product(product, days: 7)
    prices = where(product: product)
             .where("recorded_at > ?", days.days.ago)
             .order(:recorded_at)
             .pluck(:price)

    return :unknown if prices.size < 2

    first_price = prices.first
    last_price = prices.last
    change_percent = ((last_price - first_price) / first_price * 100).abs

    if change_percent < 2
      :stable
    elsif last_price < first_price
      :down
    else
      :up
    end
  end

  def self.lowest_in_period(product, days: 30)
    where(product: product)
      .where("recorded_at > ?", days.days.ago)
      .minimum(:price)
  end

  def self.highest_in_period(product, days: 30)
    where(product: product)
      .where("recorded_at > ?", days.days.ago)
      .maximum(:price)
  end

  def self.average_price(product, days: 30)
    where(product: product)
      .where("recorded_at > ?", days.days.ago)
      .average(:price)
      .to_f
      .round(2)
  end
end
