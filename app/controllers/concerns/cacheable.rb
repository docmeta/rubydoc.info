module Cacheable
  extend ActiveSupport::Concern

  included do
    before_action :set_cache_headers
  end

  private

  def set_cache_headers
    expires_in 1.day, public: true
  end
end
