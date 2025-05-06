class GemsController < ApplicationController
  include AlphaIndexable
  include Searchable
  include Pageable
  include Cacheable

  prepend_before_action do
    @title = "RubyGems"
    @collection = Library.allowed_gem.all
  end

  def index
    render "shared/library_list"
  end
end
