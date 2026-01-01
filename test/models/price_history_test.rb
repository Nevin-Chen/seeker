require "test_helper"

class PriceHistoryTest < ActiveSupport::TestCase
  test "requires price" do
    price_history = PriceHistory.new(
      product: products(:one),
      recorded_at: Time.current
    )

    assert_not price_history.valid?
    assert_includes price_history.errors[:price], "can't be blank"
  end

  test "price must be greater than zero" do
    price_history = PriceHistory.new(
      product: products(:one),
      price: -10,
      recorded_at: Time.current
    )

    assert_not price_history.valid?
  end

  test "trend_for_product returns down when prices decrease" do
    product = products(:one)

    PriceHistory.create!(product: product, price: 100, recorded_at: 7.days.ago)
    PriceHistory.create!(product: product, price: 95, recorded_at: 5.days.ago)
    PriceHistory.create!(product: product, price: 90, recorded_at: 1.day.ago)

    assert_equal :down, PriceHistory.trend_for_product(product, days: 7)
  end

  test "lowest_in_period returns minimum price" do
    product = products(:one)

    PriceHistory.create!(product: product, price: 100, recorded_at: 20.days.ago)
    PriceHistory.create!(product: product, price: 75, recorded_at: 10.days.ago)
    PriceHistory.create!(product: product, price: 90, recorded_at: 1.day.ago)

    assert_equal 75, PriceHistory.lowest_in_period(product, days: 30)
  end

  test "average_price calculates average price correctly" do
    product = products(:one)

    PriceHistory.create!(product: product, price: 100, recorded_at: 10.days.ago)
    PriceHistory.create!(product: product, price: 80, recorded_at: 5.days.ago)

    assert_equal 90.0, PriceHistory.average_price(product, days: 30)
  end
end
