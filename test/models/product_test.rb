require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "valid product with required fields" do
    product = Product.new(name: "iPhone 15", url: "https://seeker.com/iphone")
    assert product.valid?
  end

  test "invalid without name" do
    product = Product.new(url: "https://seeker.com/product")
    refute product.valid?
  end

  test "invalid without url" do
    product = Product.new(name: "Test Product")
    refute product.valid?
  end

  test "invalid with duplicate url" do
    Product.create!(name: "Product 1", url: "https://seeker.com/duplicate")
    duplicate = Product.new(name: "Product 2", url: "https://seeker.com/duplicate")
    refute duplicate.valid?
  end

  test "invalid with negative price" do
    product = Product.new(
      name: "Test Product",
      url: "https://seeker.com/product",
      current_price: -10
    )
    refute product.valid?
  end

  test "invalid with non-http url" do
    product = Product.new(
      name: "Test Product",
      url: "javascript:alert('xss')"
    )
    refute product.valid?
  end

  test "invalid with file url" do
    product = Product.new(
      name: "Test Product",
      url: "file:///etc/passwd"
    )
    refute product.valid?
  end

  test "valid with http url" do
    product = Product.new(
      name: "Test Product",
      url: "http://example.com/product"
    )
    assert product.valid?
  end

  test "valid with https url" do
    product = Product.new(
      name: "Test Product",
      url: "https://example.com/product"
    )
    assert product.valid?
  end

  test "stale? returns true when never checked" do
    product = Product.create!(name: "Test", url: "https://seeker.com/test")
    assert product.stale?
  end

  test "stale? returns true when checked over 6 hours ago" do
    product = Product.create!(
      name: "Test",
      url: "https://seeker.com/test",
      last_checked_at: 7.hours.ago
    )
    assert product.stale?
  end

  test "stale? returns false when recently checked" do
    product = Product.create!(
      name: "Test",
      url: "https://seeker.com/test",
      last_checked_at: 1.hour.ago
    )
    refute product.stale?
  end

  test "has many price alerts" do
    product = Product.create!(name: "Test", url: "https://seeker.com/test")
    assert_respond_to product, :price_alerts
  end
end
