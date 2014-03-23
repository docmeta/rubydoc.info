#!/bin/env ruby
require 'rubygems'
require_relative '../init'

class GemVersion
  attr_accessor :name, :version, :platform

  def initialize(name, version, platform)
    @name, @version, @platform = name.to_s, version.to_s, platform.to_s
  end

  def to_s
    platform == "ruby" ? version : [version,platform].join(',')
  end
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

# Keep track of updated gems
changed_gems = {}
File.readlines(REMOTE_GEMS_FILE).each do |line|
  name, rest = *line.split(/\s+/, 2)
  changed_gems[name] = rest
end if File.exist?(REMOTE_GEMS_FILE)

File.open(REMOTE_GEMS_FILE, 'w') do |file|
  libs.each do |k, v|
    line = pick_best_versions(v).join(' ')
    changed_gems.delete(k) if changed_gems[k] && changed_gems[k].strip == line.strip
    file.puts("#{k} #{line}")
  end
end

# Clear cache for gem frames page with new gems
# TODO: improve this cache invalidation to be version specific
changed_gems.keys.each do |gem_name|
  Cache.invalidate "/gems/#{gem_name[0,1]}", "/gems/#{gem_name}/",
                   "/list/gems/#{gem_name}/"
end

if changed_gems.size > 0
  puts ">> Updated #{changed_gems.size} gems:"
  puts changed_gems.keys.join(', ')
end
