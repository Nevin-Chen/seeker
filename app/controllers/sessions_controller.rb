class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to login_path, alert: "Try again later." }
  before_action :redirect_if_authenticated, only: [ :new, :create ]

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to login_path, alert: "Invalid email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to login_path, status: :see_other
  end

  private

  def redirect_if_authenticated
    redirect_to root_path, notice: "You're already signed in." if authenticated?
  end
end
