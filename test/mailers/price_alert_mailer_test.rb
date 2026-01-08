require "test_helper"

class PriceAlertMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  setup do
    @user = users(:one)
    @product = products(:one)
    @product.update!(
      image_url: "https://seeker.com/img.jpg"
    )

    @price_alert = price_alerts(:one)
  end

  test "price_dropped email" do
    email = PriceAlertMailer.price_dropped(@price_alert)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "test@example.com" ], email.from
    assert_equal [ @user.email_address ], email.to
    assert_equal "Price Drop Alert: Sony WH-1000XM5 Headphones", email.subject
  end

  test "price_dropped email contains product details" do
    email = PriceAlertMailer.price_dropped(@price_alert)

    assert_match @product.name, email.html_part.body.to_s
    assert_match @product.current_price.to_s, email.html_part.body.to_s
  end

  test "price_dropped email contains product image" do
    email = PriceAlertMailer.price_dropped(@price_alert)

    assert_match @product.image_url, email.html_part.body.to_s
  end

  test "price_dropped email contains product link" do
    email = PriceAlertMailer.price_dropped(@price_alert)

    assert_match product_url(@product), email.html_part.body.to_s
    assert_match price_alerts_url, email.html_part.body.to_s
  end

  test "price_dropped email shows savings" do
    @price_alert.update!(target_price: 300.00)
    @product.update!(current_price: 250.00)

    email = PriceAlertMailer.price_dropped(@price_alert)

    assert_match (@price_alert.target_price - @product.current_price).to_s, email.html_part.body.to_s
  end
end
