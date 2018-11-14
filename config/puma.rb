#!/usr/bin/env puma

require "shellwords"

root = File.expand_path("..", Dir.pwd)

directory root
rackup root + 'config.ru'
environment 'production'
bind 'tcp://0.0.0.0:8080'
daemonize unless ENV['DOCKERIZED']
pidfile root + 'tmp/pids/server.pid'
unless ENV['DOCKERIZED']
  log = Shellwords.shellescape(File.join(root, 'log/puma.log'))
  error_log = Shellwords.shellescape(File.join(root, 'log/puma.err.log'))
  stdout_redirect log, error_log, true
end
threads 8, 32
workers 3
