#!/bin/env ruby
require 'rubygems'

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
Gem::SpecFetcher.fetcher.list(true).values.flatten(1).each do |info|
  (libs[info[0]] ||= []) << GemVersion.new(*info)
end

File.open(File.join(File.dirname(__FILE__), '..', 'remote_gems'), 'w') do |file|
  libs.each do |k, v|
    file.puts("#{k} #{pick_best_versions(v).join(' ')}")
  end
end
