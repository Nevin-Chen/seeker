module PriceParsers
  class AmazonPriceParser < GenericPriceParser
    def parse
      whole = @doc.at_css(".a-price-whole")&.text
      fraction = @doc.at_css(".a-price-fraction")&.text

      if whole && fraction
        combined = "#{whole}#{fraction}".gsub(",", "")
        price = combined.to_f
        return price if price > 0
      end

      super
    end

    private

    def selectors
      [
        ".a-price .a-offscreen",
        "#priceblock_ourprice",
        "#priceblock_dealprice",
        '[data-a-color="price"] .a-offscreen',
        "#corePriceDisplay_desktop_feature_div .a-offscreen",
        "#tp_price_block_total_price_ww"
      ]
    end
  end
end
