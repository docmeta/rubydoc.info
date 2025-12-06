module Pageable
  extend ActiveSupport::Concern

  PAGE_SIZE = 100

  included do
    before_action :set_pagination
  end

  def set_pagination
    @page = params[:page]&.to_i || 1
    @total_pages = (@collection.except(:select).count / PAGE_SIZE.to_f).ceil
    @collection = @collection.offset((@page - 1) * PAGE_SIZE).limit(PAGE_SIZE)
  end
end
