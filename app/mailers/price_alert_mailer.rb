class PriceAlertMailer < ApplicationMailer
  default from: if Rails.env.test?
                  "test@example.com"
                else
                  ENV["GMAIL_USERNAME"]
                end

  def price_dropped(price_alert)
    @price_alert = price_alert
    @product = price_alert.product
    @user = price_alert.user

    mail(
      to: @user.email_address,
      subject: "Price Drop Alert: #{@product.name}"
    )
  end
end
