module ApplicationHelper
  def safe_product_url(product)
    return "" if product.url.blank?

    uri = URI.parse(product.url)
    if %w[http https].include?(uri.scheme)
      sanitize(product.url, tags: [])
    else
      ""
    end
  rescue URI::InvalidURIError
    ""
  end
end
