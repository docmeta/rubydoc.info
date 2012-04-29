#!/usr/bin/env ruby
# Removes cached repositories (gems, github, home)
require_relative '../init'
require 'source_cleaner'

[File.join(REPOS_PATH, '*', '*', '*'), File.join(REMOTE_GEMS_PATH, '*', '**')].each do |dir|
  Dir[dir].each do |d|
    puts ">> Deleting source files for #{d}"
    SourceCleaner.new(d).clean
  end
end
