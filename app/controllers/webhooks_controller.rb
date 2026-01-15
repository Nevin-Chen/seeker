class WebhooksController < ApplicationController
  skip_before_action :require_authentication
  skip_forgery_protection

  def scrape_products
    authenticate_webhook

    products = Product.needs_check
                      .joins(:price_alerts)
                      .where(price_alerts: { active: true })
                      .distinct

    products.find_each do |product|
      PriceCheckJob.perform_later(product.id)
    end

    render json: {
      status: "ok",
      products_queued: products.count,
      timestamp: Time.current
    }
  end

  private

  def authenticate_webhook
    unless params[:token] == ENV["WEBHOOK_SECRET"]
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
