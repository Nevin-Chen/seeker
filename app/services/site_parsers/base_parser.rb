module SiteParsers
  class BaseParser
    def initialize(doc)
      @doc = doc
    end

    def parse_price
      price_selectors.each do |selector|
        price = try_price_selector(selector)
        return price if price
      end
      nil
    end

    def parse_name
      name_selectors.each do |selector|
        name = try_text_selector(selector)
        return name if name.present?
      end
      nil
    end

    def parse_image
      image_selectors.each do |selector_hash|
        image = try_attribute_selector(selector_hash)
        return image if image.present?
      end
      nil
    end

    private

    def price_selectors
      [
        ".price",
        ".product-price",
        '[itemprop="price"]',
        ".price-current",
        "[data-price]"
      ]
    end

    def name_selectors
      [
        "h1",
        '[property="og:title"]',
        "title"
      ]
    end

    def image_selectors
      [
        { selector: '[property="og:image"]', attr: "content" },
        { selector: 'meta[name="twitter:image"]', attr: "content" },
        { selector: 'img[itemprop="image"]', attr: "src" }
      ]
    end

    def try_price_selector(selector)
      element = @doc.css(selector).first
      return nil unless element

      if element["data-price"]
        return extract_price_from_text(element["data-price"])
      end

      extract_price_from_text(element.text)
    end

    def try_text_selector(selector)
      if selector.is_a?(Hash)
        @doc.at_css(selector[:selector])&.[](selector[:attr])&.strip
      else
        @doc.at_css(selector)&.text&.strip
      end
    end

    def try_attribute_selector(selector_hash)
      @doc.at_css(selector_hash[:selector])&.[](selector_hash[:attr])
    end

    def extract_price_from_text(text)
      return nil if text.blank?

      cleaned = text.strip
      prices = cleaned.scan(/[\$£€¥]?\s*\d+[,.]?\d*/)
      return nil if prices.empty?

      price_str = prices.last.gsub(/[^\d.,]/, "")
      return nil if price_str.empty?

      price_str = normalize_price_string(price_str)

      match = price_str.match(/(\d+\.?\d*)/)
      return nil unless match

      price = match[1].to_f
      price > 0 ? price : nil
    end

    def normalize_price_string(str)
      if str.include?(",") && !str.include?(".")
        str.gsub(",", ".")
      elsif str.include?(",") && str.include?(".")
        str.gsub(",", "")
      else
        str
      end
    end
  end
end
