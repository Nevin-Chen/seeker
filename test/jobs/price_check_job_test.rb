require "test_helper"

class PriceCheckJobTest < ActiveJob::TestCase
  test "completes job successfully" do
    product = products(:pending_product)

    ProductScraper.any_instance.stubs(:scrape_with_static).returns(99.99)

    assert_nothing_raised do
      PriceCheckJob.perform_now(product.id)
    end

    product.reload
    assert_equal "success", product.check_status
  end

  test "performs price check for a valid product" do
    product = products(:pending_product)

    ProductScraper.any_instance.stubs(:scrape_with_static).returns(99.99)

    assert_nothing_raised do
      PriceCheckJob.perform_now(product.id)
    end
  end

  test "updates product when price is found" do
    product = products(:pending_product)

    ProductScraper.any_instance.stubs(:scrape_with_static).returns(99.99)

    PriceCheckJob.perform_now(product.id)

    product.reload
    assert_equal BigDecimal("99.99"), product.current_price
    assert_equal "success", product.check_status
    assert_not_nil product.last_checked_at
  end

  test "updates product status to error when scrape returns nil" do
    product = products(:pending_product)

    ProductScraper.any_instance.stubs(:scrape_with_static).returns(nil)
    ProductScraper.any_instance.stubs(:scrape_with_playwright).returns(nil)
    ProductScraper.any_instance.stubs(:sleep)

    PriceCheckJob.perform_now(product.id)

    product.reload
    assert_equal "error", product.check_status

    assert_equal BigDecimal("0.0"), product.current_price
    assert_not_nil product.last_checked_at
  end

  test "is enqueued in default queue" do
    assert_equal "default", PriceCheckJob.new.queue_name
  end

  test "triggers alerts when price drops to or below target" do
    product = products(:two)
    alert = price_alerts(:above_target_alert)

    ProductScraper.any_instance.stubs(:scrape_with_static).returns(380.00)

    alert.update_column(:last_notified_at, nil)

    PriceCheckJob.perform_now(product.id)

    alert.reload
    assert_not_nil alert.last_notified_at
  end

  test "does not trigger alerts when price above target" do
    product = products(:one)
    alert = price_alerts(:above_target_alert)

    ProductScraper.any_instance.stubs(:scrape_with_static).returns(500.00)

    alert.update!(last_notified_at: nil)

    PriceCheckJob.perform_now(product.id)

    alert.reload
    assert_nil alert.last_notified_at, "Alert should NOT be notified because new price (500) is above target (400)"
  end

  test "updates price when it changes" do
    product = products(:pending_product)
    ProductScraper.any_instance.stubs(:scrape_with_static).returns(299.99)

    assert_equal "pending", product.check_status

    PriceCheckJob.perform_now(product.id)
    product.reload

    assert_equal "success", product.check_status
    assert_equal BigDecimal("299.99"), product.current_price
  end

  test "retries on StandardError" do
    product = products(:pending_product)
    ProductScraper.any_instance.stubs(:scrape).raises(StandardError.new("Network error"))

    assert_raises StandardError do
      PriceCheckJob.perform_now(product.id)
    end
  end
end
