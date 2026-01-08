class PriceAlertsController < ApplicationController
  before_action :require_authentication
  before_action :set_price_alert, only: [ :destroy, :toggle ]

  def index
    @price_alerts = Current.user.price_alerts.includes(:product)
  end

  def create
    if Current.user.price_alerts.count >= User::MAX_ALERTS_PER_USER
      redirect_to price_alerts_path, alert: "You've reached the maximum of #{User::MAX_ALERTS_PER_USER} price alerts"
      return
    end

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

  def update
    @price_alert = Current.user.price_alerts.find(params[:id])

    if @price_alert.update(price_alert_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @price_alert.product, notice: "Target price updated" }
      end
    else
      @price_alert.reload
      respond_to do |format|
        format.turbo_stream { render :update, status: :unprocessable_entity }
        format.html { redirect_to @price_alert.product, alert: @price_alert.errors.full_messages.join(", ") }
      end
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

  def price_alert_params
    params.require(:price_alert).permit(:target_price)
  end
end
