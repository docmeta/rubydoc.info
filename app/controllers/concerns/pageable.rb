module Pageable
  extend ActiveSupport::Concern

  Pagy.options[:limit] = 100

  included do
    include Pagy::Method

    before_action :set_pagination
  end

  def set_pagination
    @page = params[:page]&.to_i || 1
    @pagy, @collection = pagy(@collection, page: @page)
  end
end
