require_relative 'init'

task :default => 'gems:update'

namespace :server do
  desc 'Start the server'
  task :start do
    sh "unicorn -E production -D -c unicorn.conf.rb"
  end
  
  desc 'Restart the server'
  task :restart do
    sh "kill -USR2 `cat tmp/pids/unicorn.pid`"
  end
  
  desc 'Shut down the server'
  task :stop do
    sh "kill -QUIT `cat tmp/pids/unicorn.pid`"
  end
end

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
  desc 'Clean up the cached gem sources and repositories'
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

namespace :stdlib do
  desc 'Installs a standard library SOURCE=pathtolib VERSION=targetversion' 
  task :install do
    require 'stdlib_installer'
    StdlibInstaller.new(ENV['SOURCE'], ENV['VERSION']).install
  end
end
