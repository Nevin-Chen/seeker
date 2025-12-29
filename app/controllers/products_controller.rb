class ProductsController < ApplicationController
  before_action :require_authentication
  before_action :set_product, only: [ :show ]

  def show
    @price_alert = Current.user.price_alerts.find_by(product: @product)
    @new_alert = PriceAlert.new(product: @product) unless @price_alert
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.find_or_initialize_by(url: product_params[:url])

    if @product.new_record?
      @product.assign_attributes(product_params.except(:target_price))
    end

    if @product.save
      @price_alert = Current.user.price_alerts.build(
        product: @product,
        target_price: product_params[:target_price]
      )

      if @price_alert.save
        PriceCheckJob.perform_later(@product.id)
        redirect_to @product
      else
        render :new, status: :unprocessable_entity
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :url, :sku, :target_price)
  end
end
