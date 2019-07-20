#!/bin/sh

cron
su app sh -c 'docker build -t docmeta/rubydoc.info:docparse docker/docparse' &
su app sh -c 'bundle exec rake gems:update server:start'
