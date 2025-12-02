class GemsController < ApplicationController
  include AlphaIndexable
  include Searchable
  include Pageable
  include Cacheable

  prepend_before_action do
    @title = "RubyGems"
    # Select only needed columns to reduce memory usage
    @collection = Library.allowed_gem.select(:id, :name, :source, :owner, :versions)
  end

  def index
    render "shared/library_list"
  end
end
