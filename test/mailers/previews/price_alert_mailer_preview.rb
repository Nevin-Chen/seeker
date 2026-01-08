# Preview all emails at http://localhost:3000/rails/mailers/price_alert_mailer
class PriceAlertMailerPreview < ActionMailer::Preview
  def price_dropped
    user = User.first_or_create!(
      email_address: "seeker@example.com"
    ) do |u|
      u.username = "seeker_user"
      u.password = "seeker"
      u.password_confirmation = "seeker"
    end

    product = Product.first_or_create!(
      name: "Apple iPad (A16) 11-inch Wi-Fi (2025, 11th generation)"
    ) do |p|
      p.url = "https://amazon.com/dp/1"
      p.current_price = 280.00
      p.image_url = "https://picsum.photos/200/200"
    end

    alert = PriceAlert.first_or_create!(
      user: user,
      product: product,
      target_price: 250.00
    )

    PriceAlertMailer.price_dropped(alert)
  end
end
