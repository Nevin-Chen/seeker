require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get signup_path
    assert_response :success
  end

  test "should redirect to root on successful create" do
    post signup_path, params: {
      user: {
        username: "new_user",
        email_address: "test@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_redirected_to root_path
  end

  test "should return unprocessable entity on failed create" do
    post signup_path, params: {
      user: {
        username: "new_user",
        email_address: "",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_response :unprocessable_entity
  end
end
