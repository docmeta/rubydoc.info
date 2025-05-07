class ErrorsController < ApplicationController
  VALID_STATUS_CODES = %w[400 404 406 422 500].freeze

  def self.constraints
    { code: Regexp.new(VALID_STATUS_CODES.join("|")) }
  end

  def show
    status_code = VALID_STATUS_CODES.include?(params[:code]) ? params[:code] : 500
    respond_to do |format|
      format.html { render status: status_code }
      format.any { head status_code }
    end
  end
end
