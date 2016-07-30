require_relative 'cache'
require_relative 'gem_store'
require 'rubygems'
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

  class << self
    def fetch_remote_gems
      libs = {}
      if Gem::VERSION < '2.0'
        Gem::SpecFetcher.fetcher.list(true).values.flatten(1).each do |info|
          (libs[info[0]] ||= []) << GemVersion.new(*info)
        end
      else # RubyGems 2.x API
        Gem::SpecFetcher.fetcher.available_specs(:released).first.values.flatten(1).each do |tuple|
          (libs[tuple.name] ||= []) << GemVersion.new(tuple.name, tuple.version, tuple.platform)
        end
      end

      libs
    end

    def update_remote_gems
      libs = fetch_remote_gems
      store = GemStore.new
      changed_gems = {}
      RemoteGem.all.each do |row|
        changed_gems[row.name] = row.versions
      end

      RemoteGem.db.transaction do
        libs.each do |name, versions|
          line = pick_best_versions(versions).join(' ')
          if changed_gems[name] && changed_gems[name].strip == line.strip
            changed_gems.delete(name)
          else
            store[name] = line
          end
        end
      end

      changed_gems.keys.each do |gem_name|
        flush_cache(gem_name)
      end

      changed_gems
    end

    def pick_best_versions(versions)
      seen = {}
      uniqversions = []
      versions.each do |ver|
        uniqversions |= [ver.version]
        (seen[ver.version] ||= []).send(ver.platform == "ruby" ? :unshift : :push, ver)
      end
      uniqversions.map {|v| seen[v].first }
    end

    def flush_cache(gem_name)
      Cache.invalidate("/gems", "/gems/~#{gem_name[0, 1]}", "/gems/#{gem_name}")
    end
  end

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
    self.class.flush_cache(gem.name)
  end
end
