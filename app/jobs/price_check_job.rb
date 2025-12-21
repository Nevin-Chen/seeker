class PriceCheckJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(product_id)
    product = Product.find(product_id)
    Rails.logger.info "Starting price check job for: #{product.name}"

    ProductScraper.new(product).scrape

    Rails.logger.info "Price check job completed for: #{product.name}"
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Product #{product_id} not found"
  end
end
