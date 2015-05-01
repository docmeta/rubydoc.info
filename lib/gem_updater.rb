require_relative 'cache'
require 'yard'

class GemVersion
  attr_accessor :name, :version, :platform

  def initialize(name, version, platform)
    @name, @version, @platform = name.to_s, version.to_s, platform.to_s
  end

  def to_s
    platform == "ruby" ? version : [version,platform].join(',')
  end
end

class GemUpdater
  include YARD::Server

  attr_accessor :gem, :settings, :app

  def initialize(app, name, version, platform='ruby')
    self.settings = app.settings
    self.app = app
    self.gem = GemVersion.new(name, version, platform)
  end

  def register
    settings.gems_adapter.add_library(LibraryVersion.new(gem.name, gem.version, nil, :remote_gem))
  end

  # TODO: improve this cache invalidation to be version specific
  def flush_cache
    Cache.invalidate("/gems", "/gems/~#{gem.name[0, 1]}", "/gems/#{gem.name}")
  end
end
