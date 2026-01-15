require "test_helper"

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @valid_token = "test_secret"
    ENV["WEBHOOK_SECRET"] = @valid_token

    @user = users(:one)
    @product = products(:three)
    @product.update(last_checked_at: 7.hours.ago)
    PriceAlert.create!(
      user: @user,
      product: @product,
      target_price: 100.00,
      active: true
    )
  end

  teardown do
    ENV["WEBHOOK_SECRET"] = @original_secret
  end

  test "should queue jobs for products needing check with valid token" do
    assert_enqueued_with(job: PriceCheckJob, args: [ @product.id ]) do
      post webhooks_scrape_products_url, params: { token: @valid_token }
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "ok", json["status"]
    assert json["products_queued"] >= 0
    assert_not_nil json["timestamp"]
  end

  test "should reject request with invalid token" do
    post webhooks_scrape_products_url, params: { token: "wrong_token" }

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal "Unauthorized", json["error"]
  end

  test "should reject request with missing token" do
    post webhooks_scrape_products_url

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal "Unauthorized", json["error"]
  end

  test "should only queue products with active alerts" do
    Product.create!(
      url: "https://amazon.com/p/123",
      name: "KitchenAid Semi Automatic Espresso Machine",
      current_price: 50.00,
      last_checked_at: 7.hours.ago
    )

    initial_count = Product.needs_check.joins(:price_alerts).where(price_alerts: { active: true }).distinct.count

    post webhooks_scrape_products_url, params: { token: @valid_token }

    json = JSON.parse(response.body)
    assert_equal initial_count, json["products_queued"]
  end

  test "should only queue products needing check" do
    product = Product.create!(
      url: "https://target.com/p/123",
      name: "Costway Baby Nursery Rocking Chair Glider and Ottoman Cushion Set Wood Beige",
      current_price: 50.00,
      last_checked_at: 1.hour.ago
    )

    PriceAlert.create!(
      user: @user,
      product: product,
      target_price: 40.00,
      active: true
    )

    initial_count = Product.needs_check.joins(:price_alerts).where(price_alerts: { active: true }).distinct.count

    post webhooks_scrape_products_url, params: { token: @valid_token }

    json = JSON.parse(response.body)
    assert_equal initial_count, json["products_queued"]
  end

  test "should not require user authentication" do
    post webhooks_scrape_products_url, params: { token: @valid_token }

    assert_response :success
  end
end
