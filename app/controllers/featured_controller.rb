class FeaturedController < ApplicationController
  include Cacheable
  include ApplicationHelper

  prepend_before_action do
    @title = "Featured Libraries"
    @collection = featured_libraries
  end

  def index
    render "shared/library_list"
  end
end
