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

  def update
    @price_alert = Current.user.price_alerts.find(params[:id])

    @price_alert.assign_attributes(price_alert_params)

    unless @price_alert.changed?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("price_alert_#{@price_alert.id}",
              partial: "price_alerts/alert_target_price",
              locals: { price_alert: @price_alert }
            ),
            turbo_stream.replace("price_alert_#{@price_alert.id}_card",
              partial: "price_alerts/alert_target_price_card",
              locals: { price_alert: @price_alert }
            )
          ]
        end
        format.html { redirect_to @price_alert.product, notice: "No changes made" }
      end
      return
    end

    if @price_alert.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @price_alert.product, notice: "Target price updated" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("price_alert_#{@price_alert.id}",
              partial: "price_alerts/alert_target_price",
              locals: { price_alert: @price_alert, error: @price_alert.errors.full_messages.join(", ") }
            ),
            turbo_stream.replace("price_alert_#{@price_alert.id}_card",
              partial: "price_alerts/alert_target_price_card",
              locals: { price_alert: @price_alert }
            )
          ], status: :unprocessable_entity
        end
        format.html { redirect_to @price_alert.product, alert: "Failed to update: #{@price_alert.errors.full_messages.join(', ')}" }
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
