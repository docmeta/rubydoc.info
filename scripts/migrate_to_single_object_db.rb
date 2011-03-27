#!/usr/bin/env ruby
# Migrates .yardocs to --single-db
require_relative '../init'
include YARD

[File.join(REPOS_PATH, '*', '*', '*'), File.join(REMOTE_GEMS_PATH, '*', '*', '*')].each do |dir|
  Dir[dir].each do |d| 
    puts ">> Migrating .yardoc to single db for #{d}"
    Dir.chdir(d)
    Registry.load!
    Registry.save
    `touch .yardoc/complete`
  end
end
