module AlphaIndexable
  extend ActiveSupport::Concern

  included do
    before_action :set_alpha_index
  end

  def set_alpha_index
    @has_alpha_index = true
    @letter = params[:letter] || default_alpha_index
    set_alpha_index_collection
  end

  def default_alpha_index
    "a"
  end

  def set_alpha_index_collection
    @collection = @collection.where("lower(name) LIKE ?", "#{@letter.downcase}%") if @letter.present?
  end
end
