module PriceAlertsHelper
  def price_alert_button_classes(active)
    base = "inline-flex items-center gap-1.5 rounded-full px-4 py-2 text-sm font-medium transition cursor-pointer"

    if active
      "#{base} bg-slate-600 text-white hover:bg-slate-500 active:bg-slate-700 focus-visible:outline-slate-600"
    else
      "#{base} bg-brand-500 text-white hover:bg-brand-400 active:bg-brand-600 focus-visible:outline-brand-500"
    end
  end
end
