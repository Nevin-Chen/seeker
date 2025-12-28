class PriceAlertsController < ApplicationController
  before_action :require_authentication
  before_action :set_price_alert, only: [ :destroy, :toggle ]

  def index
    @price_alerts = Current.user.price_alerts.includes(:product)
  end

  def create
    @product = Product.find(params[:product_id])
    @price_alert = Current.user.price_alerts.build(
      product: @product,
      target_price: params[:price_alert][:target_price]
    )

    if @price_alert.save
      redirect_to @product, notice: "Price alert created!"
    else
      redirect_to @product, alert: "Could not create alert: #{@price_alert.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @price_alert.destroy
    redirect_to products_path, notice: "Price alert removed."
  end

  def toggle
    @price_alert.update(active: !@price_alert.active)
    redirect_to product_path(@price_alert.product),
                notice: "Alert #{@price_alert.active? ? 'activated' : 'deactivated'}."
  end

  private

  def set_price_alert
    @price_alert = Current.user.price_alerts.find(params[:id])
  end
end
