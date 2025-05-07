class FeaturedController < ApplicationController
  include Cacheable
  include ApplicationHelper

  prepend_before_action do
    @title = "Featured Libraries"
    @page_title = @title
    @collection = featured_libraries
  end

  def index
    render "shared/library_list"
  end
end
