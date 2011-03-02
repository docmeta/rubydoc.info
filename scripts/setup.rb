#!/usr/bin/env ruby
require 'init'
require 'rubygems/dependency_installer'
puts ">> Running initial setup for site..."
deps = File.readlines(DEPS_FILE).reject {|l| l =~ /^\s*#/ }.map(&:strip)
puts ">> Installing dependencies (#{deps.join(', ')})..."
deps.each {|dep| Gem::DependencyInstaller.new.install(dep) unless Gem.available?(dep) }
puts ">> Updating Remote Gems file (local cache)"
load File.dirname(__FILE__) + '/update_remote_gems.rb'
require 'app' # sanity check
