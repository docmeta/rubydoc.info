#!/usr/bin/env ruby
# Removes cached repositories (gems, github, home)
$:.unshift(File.dirname(__FILE__) + '/../')

require 'init'

[File.join(REPOS_PATH, '*'), File.join(REMOTE_GEMS_PATH, '*', '**')].each do |dir|
  Dir[dir].each { |d| FileUtils.rm_rf(d) }
end
