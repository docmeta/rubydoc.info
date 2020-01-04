require 'skylight'

class YARD::Server::Commands::LibraryCommand
  include Skylight::Helpers
  instrument_method :call
end

class YARD::Server::LibraryVersion
  include Skylight::Helpers

  instrument_method :generate_yardoc
  instrument_method :clean_source
end

class ScmCheckout
  include Skylight::Helpers
  instrument_method :checkout
end
