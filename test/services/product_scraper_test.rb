require "test_helper"

class ProductScraperTest < ActiveSupport::TestCase
  setup do
    @product = products(:pending_product)
    @scraper = ProductScraper.new(@product)
  end

  test "initializes with product and extracts domain" do
    product = Product.new(
      name: "Test",
      url: "https://www.amazon.com/dp/B123"
    )
    scraper = ProductScraper.new(product)

    assert_equal product, scraper.instance_variable_get(:@product)
    assert_equal "https://www.amazon.com/dp/B123", scraper.instance_variable_get(:@url)
    assert_equal "www.amazon.com", scraper.instance_variable_get(:@domain)
  end

  test "handles invalid URLs gracefully" do
    product = Product.new(name: "Test", url: "invalid_url")
    scraper = ProductScraper.new(product)

    assert_nil scraper.instance_variable_get(:@domain)
  end

  test "scrape tries static first and falls back to playwright on failure" do
    scraper = ProductScraper.new(@product)

    scraper.expects(:scrape_with_static).returns(nil)
    scraper.expects(:sleep).with(2)
    scraper.expects(:scrape_with_playwright).returns(99.99)

    result = scraper.scrape

    assert_equal 99.99, result
  end

  test "scrape returns immediately when static succeeds" do
    scraper = ProductScraper.new(@product)

    scraper.expects(:scrape_with_static).returns(149.99)
    scraper.expects(:scrape_with_playwright).never
    scraper.expects(:sleep).never

    result = scraper.scrape

    assert_equal 149.99, result
  end

  test "scrape handles complete failure" do
    scraper = ProductScraper.new(@product)

    scraper.stubs(:scrape_with_static).returns(nil)
    scraper.stubs(:scrape_with_playwright).returns(nil)
    scraper.stubs(:sleep)

    result = scraper.scrape

    assert_nil result
    @product.reload
    assert_equal "error", @product.check_status
    assert_not_nil @product.last_checked_at
  end

  test "scrape_with_static successfully parses price" do
    mock_response = mock("response")
    mock_response.stubs(:success?).returns(true)
    mock_response.stubs(:body).returns('<span class="price">$99.99</span>')

    HTTParty.stubs(:get).returns(mock_response)
    PriceParsers::GenericPriceParser.any_instance.stubs(:parse).returns(99.99)

    scraper = ProductScraper.new(@product)
    result = scraper.send(:scrape_with_static)

    assert_equal 99.99, result
  end

  test "scrape_with_static returns nil on HTTP error" do
    mock_response = mock("response")
    mock_response.stubs(:success?).returns(false)

    HTTParty.stubs(:get).returns(mock_response)

    scraper = ProductScraper.new(@product)
    result = scraper.send(:scrape_with_static)

    assert_nil result
  end

  test "scrape_with_static handles exceptions" do
    HTTParty.stubs(:get).raises(Timeout::Error.new("Timeout"))

    scraper = ProductScraper.new(@product)

    assert_nothing_raised do
      result = scraper.send(:scrape_with_static)
      assert_nil result
    end
  end

  test "scrape_with_playwright successfully extracts price" do
    mock_playwright_browser
    PriceParsers::GenericPriceParser.any_instance.stubs(:parse).returns(199.99)

    scraper = ProductScraper.new(@product)
    result = scraper.send(:scrape_with_playwright)

    assert_equal 199.99, result
  end

  test "scrape_with_playwright handles exceptions" do
    Playwright.stubs(:create).raises(StandardError.new("Browser error"))

    scraper = ProductScraper.new(@product)
    result = scraper.send(:scrape_with_playwright)

    assert_nil result
  end

  test "parse_price_for_domain selects AmazonPriceParser for amazon.com" do
    product = Product.new(name: "Test", url: "https://www.amazon.com/dp/B123")
    scraper = ProductScraper.new(product)
    doc = Nokogiri::HTML("<html></html>")

    PriceParsers::AmazonPriceParser.any_instance.expects(:parse).returns(99.99)

    result = scraper.send(:parse_price_for_domain, doc)
    assert_equal 99.99, result
  end

  test "parse_price_for_domain selects TargetPriceParser for target.com" do
    product = Product.new(name: "Test", url: "https://www.target.com/p/123")
    scraper = ProductScraper.new(product)
    doc = Nokogiri::HTML("<html></html>")

    PriceParsers::TargetPriceParser.any_instance.expects(:parse).returns(149.99)

    result = scraper.send(:parse_price_for_domain, doc)
    assert_equal 149.99, result
  end

  test "parse_price_for_domain selects GenericPriceParser for unknown domains" do
    product = Product.new(name: "Test", url: "https://example.com/product")
    scraper = ProductScraper.new(product)
    doc = Nokogiri::HTML("<html></html>")

    PriceParsers::GenericPriceParser.any_instance.expects(:parse).returns(79.99)

    result = scraper.send(:parse_price_for_domain, doc)
    assert_equal 79.99, result
  end

  test "update_product sets price and status" do
    scraper = ProductScraper.new(@product)

    scraper.send(:update_product, 199.99, "success", "HTTParty")

    @product.reload
    assert_equal BigDecimal("199.99"), @product.current_price
    assert_equal "success", @product.check_status
    assert_not_nil @product.last_checked_at
  end

  test "update_product triggers alerts for matching prices" do
    product = products(:one)
    alert = price_alerts(:one)
    alert.update!(target_price: 400.00, last_notified_at: nil)

    scraper = ProductScraper.new(product)

    scraper.send(:update_product, 380.00, "success")

    alert.reload
    assert_not_nil alert.last_notified_at
  end

  test "handle_error sets error status and timestamp" do
    scraper = ProductScraper.new(@product)

    scraper.send(:handle_error, "Test error")

    @product.reload
    assert_equal "error", @product.check_status
    assert_not_nil @product.last_checked_at
  end

  test "check_and_notify_alerts triggers matching alerts" do
    product = products(:one)
    alert = price_alerts(:one)
    alert.update!(target_price: 400.00, last_notified_at: nil, active: true)

    scraper = ProductScraper.new(product)

    scraper.send(:check_and_notify_alerts, 380.00)

    alert.reload
    assert_not_nil alert.last_notified_at
  end

  test "check_and_notify_alerts ignores inactive alerts" do
    product = products(:one)
    alert = price_alerts(:one)
    alert.update!(target_price: 400.00, last_notified_at: nil, active: false)

    scraper = ProductScraper.new(product)

    scraper.send(:check_and_notify_alerts, 380.00)

    alert.reload
    assert_nil alert.last_notified_at
  end

  test "check_and_notify_alerts ignores alerts where price is above target" do
    product = products(:one)
    alert = price_alerts(:one)
    alert.update!(target_price: 100.00, last_notified_at: nil, active: true)

    scraper = ProductScraper.new(product)

    scraper.send(:check_and_notify_alerts, 200.00)

    alert.reload
    assert_nil alert.last_notified_at
  end

  test "extract_domain extracts domain from URL" do
    scraper = ProductScraper.new(@product)

    assert_equal "www.amazon.com", scraper.send(:extract_domain, "https://www.amazon.com/dp/B123")
    assert_equal "target.com", scraper.send(:extract_domain, "https://target.com/p/456")
  end

  test "extract_domain handles invalid URLs" do
    scraper = ProductScraper.new(@product)

    assert_nil scraper.send(:extract_domain, "not-a-url")
  end

  test "random_headers returns valid headers" do
    scraper = ProductScraper.new(@product)
    headers = scraper.send(:random_headers)

    assert headers["User-Agent"].present?
    assert_equal "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", headers["Accept"]
    assert_equal "1", headers["DNT"]
  end

  test "playwright_path returns local path if exists" do
    scraper = ProductScraper.new(@product)
    local_path = Rails.root.join("node_modules", ".bin", "playwright")

    File.stubs(:exist?).with(local_path).returns(true)

    assert_equal local_path.to_s, scraper.send(:playwright_path)
  end

  test "playwright_path returns global command if local not found" do
    scraper = ProductScraper.new(@product)

    File.stubs(:exist?).returns(false)

    assert_equal "playwright", scraper.send(:playwright_path)
  end

  private

  def mock_playwright_browser
    page = mock("page")
    page.stubs(:set_extra_http_headers)
    page.stubs(:goto)
    page.stubs(:wait_for_timeout)
    page.stubs(:content).returns('<div class="price">$199.99</div>')
    page.stubs(:screenshot)
    page.stubs(:locator).returns(stub(count: 0))

    context = mock("context")
    context.stubs(:new_page).returns(page)
    context.stubs(:close)

    browser = mock("browser")
    browser.stubs(:new_context).returns(context)

    chromium = mock("chromium")
    chromium.stubs(:launch).yields(browser)

    playwright_instance = mock("playwright")
    playwright_instance.stubs(:chromium).returns(chromium)

    Playwright.stubs(:create).yields(playwright_instance)
  end
end
