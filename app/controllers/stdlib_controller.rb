class StdlibController < ApplicationController
  include Cacheable

  prepend_before_action do
    @title = "Ruby Standard Library"
    @page_title = @title
    @collection = Library.stdlib.all
  end

  def index
    render "shared/library_list"
  end
end
