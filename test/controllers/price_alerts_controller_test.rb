require "test_helper"

class PriceAlertsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @price_alert = price_alerts(:one)
    sign_in @user
  end

  test "should update price alert and respond with turbo stream" do
    patch price_alert_url(@price_alert),
          params: { price_alert: { target_price: 299.99 } },
          as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type

    assert_match /turbo-stream.*action="replace".*target="price_alert_#{@price_alert.id}"/, response.body
    assert_match /turbo-stream.*action="replace".*target="price_alert_#{@price_alert.id}_card"/, response.body

    assert_match /299\.99/, response.body

    @price_alert.reload
    assert_equal 299.99, @price_alert.target_price
  end

  test "should update price alert and redirect for html format" do
    patch price_alert_url(@price_alert),
          params: { price_alert: { target_price: 199.99 } }

    assert_redirected_to @price_alert.product
    follow_redirect!

    assert_match /updated/i, response.body

    @price_alert.reload
    assert_equal 199.99, @price_alert.target_price
  end

  test "should not update price alert with invalid data" do
    original_price = @price_alert.target_price

    patch price_alert_url(@price_alert),
          params: { price_alert: { target_price: -10 } },
          as: :turbo_stream

    assert_response :unprocessable_entity
    assert_match /turbo-stream/, response.body

    @price_alert.reload
    assert_equal original_price, @price_alert.target_price
  end

  test "should not update price alert with blank target price" do
    original_price = @price_alert.target_price
    patch price_alert_url(@price_alert), params: { price_alert: { target_price: "" } }

    @price_alert.reload
    assert_equal original_price, @price_alert.target_price
  end

  test "user cannot update another user's price alert" do
    other_alert = price_alerts(:three)

    patch price_alert_url(other_alert), params: { price_alert: { target_price: 55.25 } }
    other_alert.reload

    assert_not_equal 55.25, other_alert.target_price
  end

  test "should not update database when price unchanged" do
    original_price = @price_alert.target_price
    original_updated_at = @price_alert.updated_at

    patch price_alert_url(@price_alert),
          params: { price_alert: { target_price: original_price } },
          as: :turbo_stream

    assert_response :success

    @price_alert.reload
    assert_equal original_price, @price_alert.target_price
    assert_equal original_updated_at.to_i, @price_alert.updated_at.to_i, "updated_at should not change"
  end


  test "multiple updates to same price alert should work" do
    patch price_alert_url(@price_alert),
          params: { price_alert: { target_price: 100.00 } },
          as: :turbo_stream

    assert_response :success
    @price_alert.reload
    assert_equal 100.00, @price_alert.target_price

    patch price_alert_url(@price_alert),
          params: { price_alert: { target_price: 200.00 } },
          as: :turbo_stream

    assert_response :success
    @price_alert.reload
    assert_equal 200.00, @price_alert.target_price

    patch price_alert_url(@price_alert),
          params: { price_alert: { target_price: 300.00 } },
          as: :turbo_stream

    assert_response :success
    @price_alert.reload
    assert_equal 300.00, @price_alert.target_price
  end
end
