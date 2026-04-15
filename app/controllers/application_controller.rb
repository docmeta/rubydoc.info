class ApplicationController < ActionController::Base
  skip_forgery_protection

  after_action :prevent_error_response_caching

  private

  def prevent_error_response_caching
    return unless response.status.to_i >= 400

    response.headers["Cache-Control"] = "no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
  end
end
