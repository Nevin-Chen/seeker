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
    @last_parser = nil
  end

  def scrape
    # Rate limit based on domain
    last_scrape = Rails.cache.read("last_scrape:#{@domain}")

    if last_scrape && last_scrape > 5.seconds.ago
      wait_time = 5 - (Time.current - last_scrape).to_i
      Rails.logger.info "⏳ Rate limiting: waiting #{wait_time}s for #{@domain}"
      sleep(wait_time)
    end

    Rails.cache.write("last_scrape:#{@domain}", Time.current)

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
      follow_redirects: true,
      max_redirects: 3
    )

    return nil unless response.success?

    doc = Nokogiri::HTML(response.body)
    parser = get_parser(doc)

    price = parser.parse_price

    if price
      @last_parser = parser
    end

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

        page.goto(@url, timeout: 20_000, waitUntil: "domcontentloaded")

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
    parser = get_parser(doc)

    price = parser.parse_price

    if price
      @last_parser = parser
    end

    price
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

  def get_parser(doc)
    parser_class = case @domain
    when /amazon\./
      SiteParsers::AmazonParser
    when /target\./
      SiteParsers::TargetParser
    else
      SiteParsers::BaseParser
    end

    parser_class.new(doc)
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
    update_attrs = {
      current_price: price,
      last_checked_at: Time.current,
      check_status: status
    }

    if @last_parser
      product_name = @last_parser.parse_name
      image_url = @last_parser.parse_image

      update_attrs[:name] = product_name if product_name.present? || @product.name.blank?
      update_attrs[:image_url] = image_url if image_url.present?
    end

    @product.update(update_attrs)

    if price_changed?(price)
      @product.price_histories.create!(
        price: price,
        recorded_at: Time.current,
        source: strategy
      )
    end

    Rails.logger.info "Site scraped using #{strategy}" if strategy

    broadcast_price_update
    check_and_notify_alerts(price)
  end

  def handle_error(message)
    @product.update(
      last_checked_at: Time.current,
      check_status: "error"
    )

    broadcast_price_update
  end

  def check_and_notify_alerts(price)
    triggered = @product.price_alerts.active.where("target_price >= ?", price)

    triggered.find_each do |alert|
      Rails.logger.info "Alert triggered: #{alert.user.username} - #{@product.name} at $#{price}"
      alert.update(last_notified_at: Time.current)
    end
  end

  def broadcast_price_update
    price_alert = @product.price_alerts.first

    ActionCable.server.broadcast(
      "product_updates_#{@product.id}",
      {
        target: "product_#{@product.id}_details",
        html: ApplicationController.render(
          partial: "products/product_details",
          locals: { product: @product.reload, price_alert: price_alert }
        )
      }
    )
  rescue => e
    Rails.logger.error "Failed to broadcast price update for product #{@product.id}: #{e.message}"
  end

  def price_changed?(new_price)
    return true if @product.price_histories.empty?

    last_recorded = @product.price_histories.order(:recorded_at).last
    return true unless last_recorded

    price_diff = (new_price - last_recorded.price).abs / last_recorded.price
    time_diff = Time.current - last_recorded.recorded_at

    price_diff > 0.01 || time_diff > 1.day
  end
end
