#!/usr/bin/env puma

root = File.dirname(__FILE__) + '/../'

directory root
rackup root + 'config.ru'
environment 'production'
bind 'tcp://0.0.0.0:8080'
daemonize unless ENV['DOCKERIZED']
pidfile root + 'tmp/pids/server.pid'
stdout_redirect root + 'log/puma.log', root + 'log/puma.err.log', true
threads 8, 32
workers 3
