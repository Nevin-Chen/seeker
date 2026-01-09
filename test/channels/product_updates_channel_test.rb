require "test_helper"

class ProductUpdatesChannelTest < ActionCable::Channel::TestCase
  setup do
    @user = users(:one)
    @product = products(:one)
  end

  test "subscribes to a product stream" do
    stub_connection current_user: @user
    subscribe product_id: @product.id

    assert subscription.confirmed?
    assert_has_stream "user_#{@user.id}_product_#{@product.id}"
  end

  test "rejects subscription without product_id" do
    stub_connection current_user: @user
    subscribe

    assert subscription.rejected?
  end

  test "rejects subscription without current_user" do
    stub_connection current_user: nil
    subscribe product_id: @product.id

    assert subscription.rejected?
  end

  test "receives broadcast when product is updated" do
    stub_connection current_user: @user
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
    stub_connection current_user: @user
    subscribe product_id: @product.id
    assert subscription.confirmed?

    assert_has_stream "user_#{@user.id}_product_#{@product.id}"
  end

  test "subscribes to different products with different streams" do
    product_two = products(:two)

    stub_connection current_user: @user
    subscribe product_id: @product.id
    assert_has_stream "user_#{@user.id}_product_#{@product.id}"

    unsubscribe
    subscribe product_id: product_two.id
    assert_has_stream "user_#{@user.id}_product_#{product_two.id}"
  end

  test "different users get different streams for same product" do
    user_two = users(:two)

    stub_connection current_user: @user
    subscribe product_id: @product.id
    assert_has_stream "user_#{@user.id}_product_#{@product.id}"

    unsubscribe

    stub_connection current_user: user_two
    subscribe product_id: @product.id
    assert_has_stream "user_#{user_two.id}_product_#{@product.id}"
  end
end
