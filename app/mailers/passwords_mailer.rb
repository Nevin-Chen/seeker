class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    @token = user.generate_token_for(:password_reset)

    mail to: user.email_address, subject: "Reset your password"
  end
end
