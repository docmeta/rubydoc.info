require_relative 'init'
require 'fileutils'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

task :default => 'gems:update'

namespace :server do
  desc 'Start the server'
  task :start => 'cache:clean_index' do
    FileUtils.mkdir_p 'tmp/pids'
    FileUtils.mkdir_p 'log'
    exec "puma -C scripts/puma.rb"
  end

  desc 'Restart the server'
  task :restart => 'cache:clean_index' do
    sh "kill -USR1 `cat tmp/pids/server.pid`"
  end
end

namespace :gems do
  desc 'Update gem list from remote'
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

namespace :docker do
  desc 'Builds documentation for SOURCE in an isolated Docker container'
  task :doc do
    source_path = ENV['SOURCE']
    host_path_file = File.join(__dir__, 'data', 'host_path')
    if File.exist?(host_path_file)
      source_path = source_path.sub(/\A\/app/, File.read(host_path_file).strip)
    end

    sh "docker run --rm -u '#{Process.uid}:#{Process.gid}' -v #{source_path.inspect}:/build 127.0.0.1:5000/rubydoc-docparse"
  end
end
