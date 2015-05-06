require_relative 'init'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

task :default => 'gems:update'

namespace :server do
  desc 'Start the server'
  task :start => 'cache:clean_index' do
    mkdir_p 'tmp/pids'
    mkdir_p 'log'
    sh "bundle exec puma -C config/puma.rb"
  end

  desc 'Restart the server'
  task :restart => 'cache:clean_index' do
    sh "kill -USR1 `cat tmp/pids/server.pid`"
  end

  desc 'Shut down the server'
  task :stop do
    sh "kill -HUP `cat tmp/pids/server.pid`"
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

  desc 'Clean HTML cache (github, gems, featured)'
  task :clean_disk_html do
    puts '>> Removing HTML cache pages'
    system 'find public/github public/gems public/featured public/docs -atime +7 -exec rm -vrf {} \;'
  end

  desc 'Clean repository cache (github, gems)'
  task :clean_disk_repos do
    puts '>> Removing gem repositories'
    system 'rm -rf repos/gems/*'
  end
end

namespace :stdlib do
  desc 'Installs a standard library SOURCE=pathtolib VERSION=targetversion'
  task :install do
    raise 'Missing SOURCE path (SOURCE=pathtolib)' unless ENV['SOURCE']
    raise 'Missing Ruby version (VERSION=targetversion)' unless ENV['VERSION']
    require 'stdlib_installer'
    StdlibInstaller.new(ENV['SOURCE'], ENV['VERSION']).install
  end
end
