#!/usr/bin/env ruby
# Removes index pages (gems, github, home)
require_relative '../init'
require_relative '../lib/cache'

Cache.invalidate *%w(/gems/* /github/* /featured /github /gems /stdlib /)