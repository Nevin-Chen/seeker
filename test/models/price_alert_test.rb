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
      url: "https://amazon.com/product/christmas_set_12",
      current_price: 200.00
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
    alert = PriceAlert.create!(
      user: @user,
      product: @product,
      target_price: 75.00
    )
    @product.update(current_price: 50.00)

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
      product: Product.create!(name: "Product 2", url: "https://amazon.com/a_product"),
      target_price: 99.99,
      active: false
    )

    assert_includes PriceAlert.active, active_alert
    refute_includes PriceAlert.active, inactive_alert
  end

  test "triggered scope returns alerts where price dropped" do
    triggered_alert = PriceAlert.create!(
      user: @user,
      product: @product,
      target_price: 75.00
    )
    @product.update(current_price: 50.00)

    product2 = Product.create!(
      name: "Product 2",
      url: "https://target.com/a_product",
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

  test "user can create up to MAX_ALERTS_PER_USER alerts" do
    (User::MAX_ALERTS_PER_USER - 1).times do |i|
      product = Product.create!(
        url: "https://amazon.com/product/#{i}"
      )
      PriceAlert.create!(
        user: @user,
        product: product,
        target_price: 99.99
      )
    end

    alert = PriceAlert.new(
      user: @user,
      product: @product,
      target_price: 99.99
    )

    assert alert.valid?
    assert alert.save
    assert_equal User::MAX_ALERTS_PER_USER, @user.price_alerts.count
  end

  test "user cannot exceed MAX_ALERTS_PER_USER alerts" do
    User::MAX_ALERTS_PER_USER.times do |i|
      product = Product.create!(
        url: "https://amazon.com/product/#{i}"
      )
      PriceAlert.create!(
        user: @user,
        product: product,
        target_price: 99.99
      )
    end

    extra_product = Product.create!(
      url: "https://amazon.com/product/extra"
    )
    alert = PriceAlert.new(
      user: @user,
      product: extra_product,
      target_price: 99.99
    )

    refute alert.valid?
    assert_includes alert.errors[:base], "You can only have #{User::MAX_ALERTS_PER_USER} active price alerts"
  end

  test "different users can each have MAX_ALERTS_PER_USER alerts" do
    other_user = User.create!(
      username: "seeker_two",
      email_address: "other@seeker.com",
      password: "password123",
      password_confirmation: "password123"
    )

    User::MAX_ALERTS_PER_USER.times do |i|
      product = Product.create!(
        url: "https://amazon.com/product/user1_#{i}"
      )
      PriceAlert.create!(
        user: @user,
        product: product,
        target_price: 99.99
      )
    end

    product = Product.create!(
      url: "https://amazon.com/product/user2_1"
    )
    alert = PriceAlert.new(
      user: other_user,
      product: product,
      target_price: 99.99
    )

    assert alert.valid?
    assert alert.save
  end

  test "inactive alerts count toward MAX_ALERTS_PER_USER limit" do
    User::MAX_ALERTS_PER_USER.times do |i|
      product = Product.create!(
        url: "https://amazon.com/product/#{i}"
      )
      PriceAlert.create!(
        user: @user,
        product: product,
        target_price: 99.99,
        active: i.even?
      )
    end

    extra_product = Product.create!(
      url: "https://amazon.com/product/extra"
    )
    alert = PriceAlert.new(
      user: @user,
      product: extra_product,
      target_price: 99.99
    )

    refute alert.valid?
  end

  test "deleting alert allows user to create new one at limit" do
    alerts = []
    User::MAX_ALERTS_PER_USER.times do |i|
      product = Product.create!(
        url: "https://amazon.com/product/#{i}"
      )
      alerts << PriceAlert.create!(
        user: @user,
        product: product,
        target_price: 99.99
      )
    end

    alerts.first.destroy

    new_product = Product.create!(
      url: "https://amazon.com/product/new"
    )
    alert = PriceAlert.new(
      user: @user,
      product: new_product,
      target_price: 99.99
    )

    assert alert.valid?
    assert alert.save
  end

  test "should_notify? returns true when price dropped and never notified" do
    alert = PriceAlert.create!(
      user: @user,
      product: @product,
      target_price: 75.00,
      last_notified_at: nil
    )
    @product.update!(current_price: 50.00)

    assert alert.should_notify?
  end

  test "should_notify? returns false when already notified" do
    alert = PriceAlert.create!(
      user: @user,
      product: @product,
      target_price: 75.00,
      last_notified_at: 1.hour.ago
      )
    @product.update!(current_price: 50.00)

    refute alert.should_notify?
  end

  test "should_notify? returns false when price above target" do
    alert = PriceAlert.create!(
      user: @user,
      product: @product,
      target_price: 75.00,
      last_notified_at: nil
    )
    @product.update!(current_price: 100.00)

    refute alert.should_notify?
  end

  test "should_notify? returns false when price is nil" do
    alert = PriceAlert.create!(
      user: @user,
      product: @product,
      target_price: 75.00,
      last_notified_at: nil
    )
    @product.update!(current_price: nil)

    refute alert.should_notify?
  end
end
