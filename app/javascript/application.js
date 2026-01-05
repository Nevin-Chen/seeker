// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";
import { createConsumer } from "@rails/actioncable";

let subscription = null;

document.addEventListener("turbo:load", function () {
  if (subscription) {
    return;
  }

  const productEl = document.querySelector("[data-product-id]");

  if (!productEl) return;

  const productId = productEl.dataset.productId;
  const consumer = createConsumer();

  subscription = consumer.subscriptions.create(
    { channel: "ProductUpdatesChannel", product_id: productId },
    {
      connected() {},

      received(data) {
        const message = typeof data === "string" ? JSON.parse(data) : data;

        const el = document.getElementById(message.target);

        if (el && message.html) {
          el.outerHTML = message.html;
        }
      }
    }
  );
});

document.addEventListener("turbo:before-render", function () {
  if (subscription) {
    subscription.unsubscribe();
    subscription = null;
  }
});
