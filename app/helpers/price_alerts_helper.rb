module PriceAlertsHelper
  def price_alert_button_classes(active)
    base = "inline-flex items-center gap-1.5 rounded-full px-4 py-2 text-sm font-medium transition cursor-pointer"

    if active
      "#{base} bg-gray-400 text-white hover:bg-gray-300 active:bg-gray-500 focus-visible:outline-gray-400"
    else
      "#{base} bg-gray-800 text-white hover:bg-gray-700 active:bg-gray-900 focus-visible:outline-gray-800"
    end
  end
end
