class ProductUpdatesChannel < ApplicationCable::Channel
  def subscribed
    product_id = params[:product_id]

    reject if product_id.blank?

    channel_name = "product_updates_#{product_id}"

    stream_from channel_name do |message|
      transmit message
    end
  end

  def unsubscribed
    Rails.logger.info "Unsubscribed from ProductUpdatesChannel"
  end
end
