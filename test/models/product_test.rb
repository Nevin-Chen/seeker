require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "valid product with required fields" do
    product = Product.new(url: "https://amazon.com/iphone")
    assert product.valid?
  end

  test "invalid without url" do
    product = Product.new(name: "Test Product")
    refute product.valid?
  end

  test "invalid with duplicate url" do
    Product.create!(url: "https://amazon.com/duplicate")
    duplicate = Product.new(url: "https://amazon.com/duplicate")
    refute duplicate.valid?
  end

  test "invalid with negative price" do
    product = Product.new(
      url: "https://amazon.com/product",
      current_price: -10
    )
    refute product.valid?
  end

  test "invalid with non-http url" do
    product = Product.new(url: "javascript:alert('xss')")
    refute product.valid?
    assert_includes product.errors[:url], "must be a valid HTTP or HTTPS URL"
  end

  test "invalid with file url" do
    product = Product.new(url: "file:///etc/passwd")
    refute product.valid?
    assert_includes product.errors[:url], "must be a valid HTTP or HTTPS URL"
  end

  test "valid with http url" do
    product = Product.new(url: "http://target.com/product")
    assert product.valid?
  end

  test "valid with allowed domain amazon.com" do
    product = Product.new(url: "https://www.amazon.com/product/123")
    assert product.valid?
  end

  test "valid with allowed domain target.com" do
    product = Product.new(url: "https://target.com/product")
    assert product.valid?
  end

  test "valid with allowed domain walmart.com" do
    product = Product.new(url: "https://www.walmart.com/ip/12345")
    assert product.valid?
  end

  test "valid with amazon subdomain" do
    product = Product.new(url: "https://smile.amazon.com/product")
    assert product.valid?
  end

  test "valid with amazon country domain" do
    product = Product.new(url: "https://www.amazon.co.uk/product")
    assert product.valid?
  end

  test "invalid with non-whitelisted domain" do
    product = Product.new(url: "https://example.com/product")
    refute product.valid?
    assert_includes product.errors[:url], "must be from an allowed retailer: #{Product::ALLOWED_DOMAINS.join(', ')}"
  end

  test "valid with localhost in development" do
    Rails.env = ActiveSupport::StringInquirer.new("development")
    product = Product.new(url: "http://localhost:3000/product")
    assert product.valid?
  end

  test "invalid with localhost in production" do
    Rails.env = ActiveSupport::StringInquirer.new("production")
    product_one = Product.new(url: "http://localhost:3000/product")
    refute product_one.valid?
    assert_includes product_one.errors[:url], "localhost URLs are only allowed in development"

    product_two = Product.new(url: "http://127.0.0.1:3000/product")
    refute product_two.valid?
    assert_includes product_two.errors[:url], "localhost URLs are only allowed in development"
  end

  test "invalid with private IP 10.x in production" do
    Rails.env = ActiveSupport::StringInquirer.new("production")
    refute_private_url("http://10.0.0.1/product")
  end

  test "invalid with private IP 192.168.x in production" do
    Rails.env = ActiveSupport::StringInquirer.new("production")
    refute_private_url("http://192.168.1.1/product")
  end

  test "invalid with private IP 172.16-31.x in production" do
    Rails.env = ActiveSupport::StringInquirer.new("production")
    refute_private_url("http://172.16.0.1/product")
  end

  test "invalid with AWS metadata IP in production" do
    Rails.env = ActiveSupport::StringInquirer.new("production")
    refute_private_url("http://169.254.169.254/latest/meta-data")
  end

  test "stale? returns true when never checked" do
    product = Product.create!(url: "https://amazon.com/test")
    assert product.stale?
  end

  test "stale? returns true when checked over 6 hours ago" do
    product = Product.create!(
      url: "https://amazon.com/test",
      last_checked_at: 7.hours.ago
    )
    assert product.stale?
  end

  test "stale? returns false when recently checked" do
    product = Product.create!(
      url: "https://amazon.com/test",
      last_checked_at: 1.hour.ago
    )
    refute product.stale?
  end

  test "has many price alerts" do
    product = Product.create!(url: "https://amazon.com/test")
    assert_respond_to product, :price_alerts
  end

  private

  def refute_private_url(url)
    Rails.env = ActiveSupport::StringInquirer.new("production")
    product = Product.new(url: url)
    refute product.valid?
    assert_includes product.errors[:url], "cannot be a private network address"
  end
end
