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
    bundle = "bundle exec " unless ENV['DOCKERIZED']
    sh "#{bundle}puma -C config/puma.rb"
  end

  desc 'Restart the server'
  task :restart => 'cache:clean_index' do
    sh "kill -USR1 `cat tmp/pids/server.pid`"
  end

  desc 'Shut down the server'
  task :stop do
    sh "kill -9 `cat tmp/pids/server.pid`"
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

DOCKER_IMAGE = "docmeta/rubydoc.info:latest"

namespace :docker do
  desc 'Builds documentation for SOURCE at VERSION given a TYPE'
  task :doc do
    sh "docker run -v #{ENV['SOURCE'].inspect}:/build lsegal/yard-build:latest"
  end


  desc 'Build docker image'
  task :build do
    sh "docker build -t #{DOCKER_IMAGE} ."
  end

  desc 'Push docker image'
  task :push do
    sh "docker push #{DOCKER_IMAGE}"
  end

  desc 'Start docker image'
  task :start do
    mkdir_p 'tmp/pids'
    mkdir_p 'log'
    paths = []
    File.readlines('.dockerignore').each do |line|
      line = line.strip
      next if line.empty?
      paths << "-v #{Dir.pwd}/#{line}:/app/#{line}"
    end
    sh "docker run -d -p 8080:8080 #{paths.join(" ")} #{DOCKER_IMAGE}"
  end

  task :shell do
    pid = `docker ps -q`.strip.split(/\r?\n/).first
    sh "docker exec -it #{pid} /bin/bash"
  end

  task :git_pull do
    sh "git pull origin master"
  end

  desc 'Pull latest image'
  task :pull do
    sh "docker pull #{DOCKER_IMAGE}"
  end

  desc 'Stops docker image'
  task :stop do
    pids = `docker ps -f label=docmeta.rubydoc -q`.strip
    sh "docker rm -f #{pids}"
  end

  desc 'Restart docker image'
  task :restart => [:stop, :start]

  desc "Pull and update"
  task :upgrade => [:git_pull, :pull, :restart]
end
