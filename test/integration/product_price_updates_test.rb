require "test_helper"

class ProductPriceUpdatesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @product = products(:one)
    @price_alert = price_alerts(:one)

    sign_in @user
  end

  test "product details update via ActionCable after scrape" do
    get product_path(@product)
    assert_response :success

    old_price = @product.current_price
    new_price = old_price - 10.00

    @product.update!(
      current_price: new_price,
      name: "Updated Product Name",
      last_checked_at: Time.current
    )

    html = ApplicationController.render(
      partial: "products/product_details",
      locals: { product: @product.reload, price_alert: @price_alert }
    )

    assert_includes html, "Updated Product Name"
    assert_includes html, format("%.2f", new_price)
  end

  test "broadcast includes all product information" do
    @product.update!(
      name: "Product",
      current_price: 20.00,
      image_url: "https://seeker.com/image.jpg",
    )

    html = ApplicationController.render(
      partial: "products/product_details",
      locals: { product: @product, price_alert: @price_alert }
    )

    assert_includes html, "Product"
    assert_includes html, "20.00"
    assert_includes html, "https://seeker.com/image.jpg"
  end

  test "broadcast shows loading state when price is nil" do
    @product.update!(current_price: nil)

    html = ApplicationController.render(
      partial: "products/product_details",
      locals: { product: @product, price_alert: @price_alert }
    )

    assert_includes html, "Checking price..."
  end

  test "broadcast includes price alert target price" do
    @price_alert.update!(target_price: 50.00)

    html = ApplicationController.render(
      partial: "products/product_details",
      locals: { product: @product, price_alert: @price_alert }
    )

    assert_includes html, "50.00"
    assert_includes html, "Target Price"
  end
end
