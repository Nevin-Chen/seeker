class ProductUpdatesChannel < ApplicationCable::Channel
  def subscribed
    product_id = params[:product_id]

    if product_id.blank? || current_user.blank?
      reject
      return
    end

    channel_name = "user_#{current_user.id}_product_#{product_id}"

    stream_from channel_name do |message|
      transmit message
    end
  end

  def unsubscribed
    Rails.logger.info "Unsubscribed from ProductUpdatesChannel"
  end
end
