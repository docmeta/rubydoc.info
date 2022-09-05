#!/usr/bin/env puma

root = File.dirname(__FILE__) + '/../'

directory root
rackup root + 'config.ru'
environment 'production'
bind 'tcp://0.0.0.0:8080'
pidfile root + 'tmp/pids/server.pid'
unless ENV['DOCKERIZED']
  stdout_redirect root + 'log/puma.log', root + 'log/puma.err.log', true
end
threads 4, 64
workers 8
preload_app!

before_fork do
  require_relative '../lib/preload'
  AppPreloader.preload!
end
