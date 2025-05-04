module Searchable
  extend ActiveSupport::Concern

  included do
    before_action :load_search_query, if: -> { params[:q].present? }
  end

  def load_search_query
    @search = params[:q]
    @exact_match = @collection.dup.where("lower(name) = ?", @search.downcase).first
    @collection = @collection.where("lower(name) LIKE ? AND lower(name) != ?", "%#{@search.downcase}%", @search.downcase)
  end
end
