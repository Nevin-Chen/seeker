class HealthController < ApplicationController
  skip_before_action :require_authentication, only: :show

  def show
    render plain: "OK"
  end
end
