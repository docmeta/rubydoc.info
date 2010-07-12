#!/bin/env ruby
require 'rubygems'

libs = {}
Gem::SpecFetcher.fetcher.list(true).values.flatten(1).each do |info|
  libs[info[0]] ||= []
  libs[info[0]] |= [info[1].to_s]
end

File.open(File.join(File.dirname(__FILE__), '..', 'remote_gems'), 'w') do |file|
  libs.each do |k, v|
    file.puts("#{k} #{v.join(' ')}")
  end
end
