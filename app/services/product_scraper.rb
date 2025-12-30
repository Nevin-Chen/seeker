require "playwright"

class ProductScraper
  USER_AGENTS = [
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
  ].freeze

  def initialize(product)
    @product = product
    @url = product.url
    @domain = extract_domain(@url)
  end

  def scrape
    # Rate limit
    last_scrape = Rails.cache.read("last_scrape:#{@domain}")

    if last_scrape && last_scrape > 5.seconds.ago
      wait_time = 5 - (Time.current - last_scrape).to_i
      Rails.logger.info "⏳ Rate limiting: waiting #{wait_time}s for #{@domain}"
      sleep(wait_time)
    end

    price = scrape_with_static

    if price
      update_product(price, "success", "HTTParty")
      return price
    end

    sleep(2)

    price = scrape_with_playwright

    if price
      update_product(price, "success", "Playwright")
      return price
    end

    handle_error("Scraping failed")
    nil
  end

  private

  def scrape_with_static
    response = HTTParty.get(@url,
      headers: random_headers,
      timeout: 10,
      follow_redirects: true
    )

    return nil unless response.success?

    doc = Nokogiri::HTML(response.body)
    price = parse_price_for_domain(doc)

    price
  rescue => e
    Rails.logger.warn "Scraping with HTTParty failed: #{e.message}"
    nil
  end

  def scrape_with_playwright
    html = nil

    Playwright.create(playwright_cli_executable_path: playwright_path) do |playwright|
      playwright.chromium.launch(headless: true) do |browser|
        context = browser.new_context(
          viewport: { width: 1920, height: 1080 }
        )

        page = context.new_page

        page.set_extra_http_headers(
          "User-Agent" => USER_AGENTS.sample
        )

        page.goto(@url, timeout: 60_000, waitUntil: "domcontentloaded")

        dismiss_popups(page)

        page.wait_for_timeout(2000)

        html = page.content

        if Rails.env.development?
          FileUtils.mkdir_p(Rails.root.join("tmp", "debug_screenshots"))
          screenshot_path = Rails.root.join("tmp", "debug_screenshots", "#{@product.id}_#{Time.current.to_i}.png")
          page.screenshot(path: screenshot_path.to_s)
          Rails.logger.info "  📸 Screenshot saved: #{screenshot_path}"
        end

        context.close
      end
    end

    return nil unless html

    doc = Nokogiri::HTML(html)
    parse_price_for_domain(doc)
  rescue => e
    Rails.logger.error "Playwright error: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n") if Rails.env.development?
    nil
  end

  def dismiss_popups(page)
    dismiss_patterns = [
      'button:has-text("Close")',
      'button:has-text("Reject All")',
      'button:has-text("Accept")',
      '[aria-label*="Close"]',
      ".modal-close",
      "#onetrust-reject-all-handler"
    ]

    dismiss_patterns.each do |pattern|
      begin
        if page.locator(pattern).count > 0
          page.locator(pattern).first.click(timeout: 2000)
          page.wait_for_timeout(500)
        end
      rescue
      end
    end
  end

  def parse_price_for_domain(doc)
    parser_class = case @domain
    when /amazon\./
                     PriceParsers::AmazonPriceParser
    when /target\./
                     PriceParsers::TargetPriceParser
    else
                     PriceParsers::GenericPriceParser
    end

    parser_class.new(doc).parse
  end

  def playwright_path
    local_path = Rails.root.join("node_modules", ".bin", "playwright")
    return local_path.to_s if File.exist?(local_path)

    "playwright"
  end

  def random_headers
    {
      "User-Agent" => USER_AGENTS.sample,
      "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      "Accept-Language" => "en-US,en;q=0.9",
      "Accept-Encoding" => "gzip, deflate, br",
      "DNT" => "1"
    }
  end

  def extract_domain(url)
    URI.parse(url).host.downcase
  rescue
    nil
  end

  def update_product(price, status, strategy = nil)
    product_name = extract_product_name
    image_url = extract_product_image

    update_attrs = {
      current_price: price,
      last_checked_at: Time.current,
      check_status: status
    }

    update_attrs[:name] = product_name if product_name.present? || @product.name.blank?
    update_attrs[:image_url] = image_url if image_url.present?

    @product.update(update_attrs)

    Rails.logger.info "Site scraped using #{strategy}" if strategy

    check_and_notify_alerts(price)
  end

  def handle_error(message)
    @product.update(
      last_checked_at: Time.current,
      check_status: "error"
    )
  end

  def check_and_notify_alerts(price)
    triggered = @product.price_alerts.active.where("target_price >= ?", price)

    triggered.find_each do |alert|
      Rails.logger.info "Alert triggered: #{alert.user.username} - #{@product.name} at $#{price}"
      alert.update(last_notified_at: Time.current)
    end
  end


  private

  def extract_product_name
    return nil unless @last_doc

    case @domain
    when /amazon\./
      extract_amazon_name
    when /target\./
      extract_target_name
    else
      extract_generic_name
    end
  end

  def extract_amazon_name
    @last_doc.at_css("#productTitle")&.text&.strip ||
    @last_doc.at_css("h1.product-title")&.text&.strip
  end

  def extract_target_name
    @last_doc.at_css('[data-test="product-title"]')&.text&.strip ||
    @last_doc.at_css("h1")&.text&.strip
  end

  def extract_generic_name
    @last_doc.at_css("h1")&.text&.strip ||
    @last_doc.at_css('[property="og:title"]')&.[]("content") ||
    @last_doc.at_css("title")&.text&.strip
  end

  def extract_product_image
    return nil unless @last_doc

    case @domain
    when /amazon\./
      extract_amazon_image
    when /target\./
      extract_target_image
    else
      extract_generic_image
    end
  end

  def extract_amazon_image
    @last_doc.at_css("#landingImage")&.[]("src") ||
    @last_doc.at_css(".a-dynamic-image")&.[]("src") ||
    @last_doc.at_css("[data-old-hires]")&.[]("data-old-hires")
  end

  def extract_target_image
    @last_doc.at_css('[data-test="product-image"]')&.[]("src") ||
    @last_doc.at_css('img[alt*="product"]')&.[]("src")
  end

  def extract_generic_image
    @last_doc.at_css('[property="og:image"]')&.[]("content") ||
    @last_doc.at_css('meta[name="twitter:image"]')&.[]("content") ||
    @last_doc.at_css('img[itemprop="image"]')&.[]("src")
  end
end
