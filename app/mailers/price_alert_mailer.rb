class PriceAlertMailer < ApplicationMailer
  default from: ENV["GMAIL_USERNAME"]

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
