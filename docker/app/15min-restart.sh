#!/bin/sh

cd /app
su app sh -c "bundle exec gems:update cache:clean_index server:restart"
