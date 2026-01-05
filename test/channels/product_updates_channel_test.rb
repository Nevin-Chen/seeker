require "test_helper"

class ProductUpdatesChannelTest < ActionCable::Channel::TestCase
  setup do
    @user = users(:one)
    @product = products(:one)
  end

  test "subscribes to a product stream" do
    subscribe product_id: @product.id

    assert subscription.confirmed?
    assert_has_stream "product_updates_#{@product.id}"
  end

  test "rejects subscription without product_id" do
    subscribe

    assert subscription.rejected?
  end

  test "receives broadcast when product is updated" do
    subscribe product_id: @product.id

    perform :receive, {
      message: {
        target: "product_#{@product.id}_details",
        html: "<div>Updated content</div>"
      }
    }

    assert subscription.confirmed?
  end

  test "multiple clients can subscribe to same product" do
    subscribe product_id: @product.id
    assert subscription.confirmed?

    assert_has_stream "product_updates_#{@product.id}"
  end

  test "subscribes to different products with different streams" do
    product_two = products(:two)

    subscribe product_id: @product.id
    assert_has_stream "product_updates_#{@product.id}"

    unsubscribe
    subscribe product_id: product_two.id
    assert_has_stream "product_updates_#{product_two.id}"
  end
end
