class HelpController < ApplicationController
  layout "modal"

  def index
    @no_margin = true
  end
end
