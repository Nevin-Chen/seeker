require "test_helper"

class PriceCheckJobTest < ActiveJob::TestCase
  test "performs scraping for given product" do
    product = products(:pending_product)

    scraper = mock("scraper")
    scraper.expects(:scrape).once

    ProductScraper.expects(:new).with(product).returns(scraper)

    PriceCheckJob.perform_now(product.id)
  end

  test "enqueues job with product id" do
    product = products(:pending_product)

    assert_enqueued_with(job: PriceCheckJob, args: [ product.id ]) do
      PriceCheckJob.perform_later(product.id)
    end
  end

  test "job is in default queue" do
    assert_equal "default", PriceCheckJob.new.queue_name
  end

  test "retries on StandardError" do
    product = products(:pending_product)

    scraper = mock("scraper")
    scraper.stubs(:scrape).raises(StandardError.new("Network error"))

    ProductScraper.stubs(:new).returns(scraper)

    assert_raises StandardError do
      PriceCheckJob.perform_now(product.id)
    end
  end

  test "passes correct product to scraper" do
    product = products(:one)

    ProductScraper.expects(:new).with do |arg|
      arg.id == product.id && arg.is_a?(Product)
    end.returns(stub(scrape: 99.99))

    PriceCheckJob.perform_now(product.id)
  end
end
