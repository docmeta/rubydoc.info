#!/bin/env ruby
require_relative '../lib/gem_updater'

changed_gems = GemUpdater.update_remote_gems
if changed_gems.size > 0
  puts ">> Updated #{changed_gems.size} gems:"
  puts changed_gems.keys.join(', ')
end
