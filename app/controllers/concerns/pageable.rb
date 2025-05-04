module Pageable
  extend ActiveSupport::Concern

  Pagy::DEFAULT[:limit] = 100
  Pagy::DEFAULT[:size] = 10

  included do
    include Pagy::Backend

    before_action :set_pagination
  end

  def set_pagination
    @page = params[:page].to_i || 1
    @pagy, @collection = pagy(@collection)
  end
end
