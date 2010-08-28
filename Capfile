require 'capistrano/version'
require 'rubygems'
load 'deploy' if respond_to?(:namespace) # cap2 differentiator

# standard settings
set :application, "rubydoc.info"
set :domain, "rubydoc.info"
role :app, domain
role :web, domain
role :db,  domain, :primary => true

# environment settings
set :user, "deploy"
set :group, "deploy"
set :deploy_to, "/var/www/apps/#{application}"
set :deploy_via, :remote_cache
default_run_options[:pty] = true

# scm settings
set :repository, "git://github.com/lsegal/rubydoc.info.git"
set :scm, "git"
set :branch, "master"
#set :git_enable_submodules, 1

namespace :deploy do
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end

  task :cold do
    # no migrations to run
    update_code

    run "cp #{release_path}/config.yaml.sample #{shared_path}/config.yaml"
    run "mkdir -p #{shared_path}/repos"
    run "git clone git://github.com/lsegal/yard.git #{shared_path}/yard"

    symlink
    restart
  end
end

namespace :rubydoc do
  task :symlink, :roles => [:app] do
    run "ln -s #{shared_path}/config.yaml #{release_path}/config.yaml"
    run "ln -s #{shared_path}/repos #{release_path}/repos"
    run "ln -s #{shared_path}/yard #{release_path}/yard"
  end
end

after "deploy:symlink", "rubydoc:symlink"
