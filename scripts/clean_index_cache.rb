#!/usr/bin/env ruby
# Removes index pages (gems, github, home)
require_relative '../init'

['gems/*.html', 'github/*.html', 'featured.html', 'github.html', 'gems.html', 'index.html', 'stdlib.html', '.html'].each do |file|
  system "rm #{File.join(STATIC_PATH, file)}"
end
