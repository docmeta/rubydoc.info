#!/usr/bin/env ruby
# Removes index pages (gems, github, home)
$:.unshift(File.dirname(__FILE__) + '/../')

require 'init'

['gems/*.html', 'github/*.html', 'featured.html', 'github.html', 'gems.html', '.html'].each do |file|
  system "rm #{File.join(STATIC_PATH, file)}"
end
