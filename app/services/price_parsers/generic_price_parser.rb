module PriceParsers
  class GenericPriceParser
    def initialize(doc)
      @doc = doc
    end

    def parse
      selectors.each do |selector|
        price = try_selector(selector)
        return price if price
      end
      nil
    end

    private

    def selectors
      [
        ".price",
        ".product-price",
        '[itemprop="price"]',
        ".price-current",
        ".price__current",
        "[data-price]",
        ".product__price",
        ".sales .value",
        '[data-testid="price"]'
      ]
    end

    def try_selector(selector)
      element = @doc.css(selector).first
      return nil unless element

      if element["data-price"]
        return extract_number(element["data-price"])
      end

      price_text = element.text.strip
      extract_number(price_text)
    end

    def extract_number(text)
      cleaned = text.strip

      prices = cleaned.scan(/[\$£€¥]?\s*\d+[,.]?\d*/)
      return nil if prices.empty?

      price_str = prices.last.gsub(/[^\d.,]/, "")

      return nil if price_str.empty?

      if price_str.include?(",") && !price_str.include?(".")
        price_str = price_str.gsub(",", ".")
      elsif price_str.include?(",") && price_str.include?(".")
        price_str = price_str.gsub(",", "")
      end

      match = price_str.match(/(\d+\.?\d*)/)
      return nil unless match

      price = match[1].to_f
      price > 0 ? price : nil
    end
  end
end
