require "test_helper"

class PriceAlertTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      username: "seeker",
      email_address: "test@seeker.com",
      password: "password123",
      password_confirmation: "password123"
    )

    @product = Product.create!(
      name: "Christmas Decoration Set (12 Pieces)",
      url: "https://seeker.com/product/christmas_set_12"
    )
  end

  test "valid price alert" do
    alert = PriceAlert.new(
      user: @user,
      product: @product,
      target_price: 99.99
    )
    assert alert.valid?
  end

  test "invalid without target_price" do
    alert = PriceAlert.new(user: @user, product: @product)
    refute alert.valid?
  end

  test "invalid with negative target_price" do
    alert = PriceAlert.new(
      user: @user,
      product: @product,
      target_price: -10
    )
    refute alert.valid?
  end

  test "invalid with zero target_price" do
    alert = PriceAlert.new(
      user: @user,
      product: @product,
      target_price: 0
    )
    refute alert.valid?
  end

  test "user cannot have duplicate alert for same product" do
    PriceAlert.create!(
      user: @user,
      product: @product,
      target_price: 99.99
    )

    duplicate = PriceAlert.new(
      user: @user,
      product: @product,
      target_price: 89.99
    )

    refute duplicate.valid?
  end

  test "different users can alert same product" do
    other_user = User.create!(
      username: "seeker_two",
      email_address: "other@seeker.com",
      password: "password123",
      password_confirmation: "password123"
    )

    PriceAlert.create!(user: @user, product: @product, target_price: 99.99)
    other_alert = PriceAlert.new(user: other_user, product: @product, target_price: 89.99)

    assert other_alert.valid?
  end

  test "price_dropped? returns true when price at or below target" do
    @product.update(current_price: 50.00)
    alert = PriceAlert.create!(
      user: @user,
      product: @product,
      target_price: 75.00
    )

    assert alert.price_dropped?
  end

  test "price_dropped? returns false when price above target" do
    @product.update(current_price: 100.00)
    alert = PriceAlert.create!(
      user: @user,
      product: @product,
      target_price: 75.00
    )

    refute alert.price_dropped?
  end

  test "price_dropped? returns false when price is nil" do
    alert = PriceAlert.create!(
      user: @user,
      product: @product,
      target_price: 75.00
    )

    refute alert.price_dropped?
  end

  test "has default active status of true" do
    alert = PriceAlert.create!(
      user: @user,
      product: @product,
      target_price: 99.99
    )

    assert alert.active?
  end

  test "belongs to user" do
    alert = PriceAlert.create!(
      user: @user,
      product: @product,
      target_price: 99.99
    )
    assert_equal @user, alert.user
  end

  test "belongs to product" do
    alert = PriceAlert.create!(
      user: @user,
      product: @product,
      target_price: 99.99
    )
    assert_equal @product, alert.product
  end

  test "active scope returns only active alerts" do
    active_alert = PriceAlert.create!(
      user: @user,
      product: @product,
      target_price: 99.99,
      active: true
    )

    inactive_alert = PriceAlert.create!(
      user: @user,
      product: Product.create!(name: "Product 2", url: "https://example.com/test2"),
      target_price: 99.99,
      active: false
    )

    assert_includes PriceAlert.active, active_alert
    refute_includes PriceAlert.active, inactive_alert
  end

  test "triggered scope returns alerts where price dropped" do
    @product.update(current_price: 50.00)
    triggered_alert = PriceAlert.create!(
      user: @user,
      product: @product,
      target_price: 75.00
    )

    product2 = Product.create!(
      name: "Product 2",
      url: "https://example.com/test2",
      current_price: 100.00
    )
    not_triggered_alert = PriceAlert.create!(
      user: @user,
      product: product2,
      target_price: 75.00
    )

    assert_includes PriceAlert.triggered, triggered_alert
    refute_includes PriceAlert.triggered, not_triggered_alert
  end
end
