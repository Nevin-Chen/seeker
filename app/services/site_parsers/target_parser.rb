module SiteParsers
  class TargetParser < BaseParser
    private

    def price_selectors
      [
        '[data-test="product-price"]',
        '[data-test="product-price-value"]',
        'span[data-test="product-price"]',
        ".h-text-bs",
        '[data-test="currentPrice"]'
      ]
    end

    def name_selectors
      [
        '[data-test="product-title"]',
        "h1"
      ] + super
    end

    def image_selectors
      [
        { selector: '[data-test="product-image"]', attr: "src" },
        { selector: 'img[alt*="product"]', attr: "src" }
      ] + super
    end
  end
end
