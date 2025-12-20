module PriceParsers
  class TargetPriceParser < GenericPriceParser
    private

    def selectors
      [
        '[data-test="product-price"]',
        '[data-test="product-price-value"]',
        'span[data-test="product-price"]',
        ".h-text-bs",
        '[data-test="currentPrice"]',
        ".styles__StyledHeading-sc-1t8bnzh-0"
      ]
    end
  end
end
