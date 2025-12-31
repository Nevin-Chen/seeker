module SiteParsers
  class AmazonParser < BaseParser
    def parse_price
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

    def price_selectors
      [
        ".a-price .a-offscreen",
        "#priceblock_ourprice",
        "#priceblock_dealprice",
        '[data-a-color="price"] .a-offscreen',
        "#corePriceDisplay_desktop_feature_div .a-offscreen",
        "#tp_price_block_total_price_ww"
      ]
    end

    def name_selectors
      [
        "#productTitle",
        "h1.product-title"
      ] + super
    end

    def image_selectors
      [
        { selector: "#landingImage", attr: "src" },
        { selector: ".a-dynamic-image", attr: "src" },
        { selector: "[data-old-hires]", attr: "data-old-hires" }
      ] + super
    end
  end
end
