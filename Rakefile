$:.unshift(File.dirname(__FILE__))
$:.unshift(File.dirname(__FILE__) + '/lib')
$:.unshift(File.dirname(__FILE__) + '/yard/lib')
require 'yard'

task :default => 'gems:update'

namespace :gems do
  desc 'Update gem list from Rubygems.org'
  task :update do
    puts ">> Updating Remote Gems file (local cache)"
    load('scripts/update_remote_gems.rb')
  end
end

namespace :docs do
  desc 'Clean up old docs to conserve space'
  task :clean do
    puts ">> Removing outdated doc directories"
    load('scripts/clean_docs.rb')
  end
end

namespace :repos do
  desc 'Cleana up the cached gem sources and repositories'
  task :clean do
    puts ">> Removing cached gem sources and repositories"
    load('scripts/clean_repos.rb')
  end
end

namespace :cache do
  desc 'Clean index cache pages (github, gems, featured)'
  task :clean_index do
    puts '>> Removing index cache pages'
    load('scripts/clean_index_cache.rb')
  end
end
