require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid email and password" do
    user = User.new(
      username: "new_user",
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    assert user.valid?
  end

  test "invalid without email" do
    user = User.new(
      username: "new_user",
      password: "password123"
    )
    refute user.valid?
  end

  test "invalid without username" do
    user = User.new(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    refute user.valid?
  end

  test "invalid email format" do
    user = User.new(
      username: "new_user",
      email_address: "an_invalid_email",
      password: "password123",
      password_confirmation: "password123"
    )
    refute user.valid?
  end

  test "invalid with duplicate email" do
    User.create!(
      username: "new_user",
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    duplicate_user = User.new(
      username: "new_user",
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    refute duplicate_user.valid?
  end

  test "invalid with mismatched passwords" do
    user = User.new(
      username: "new_user",
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "1234"
    )
    refute user.valid?
  end

    test "has default role of user" do
    user = User.create!(
      username: "new_user",
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    assert_equal "user", user.role
  end
end
